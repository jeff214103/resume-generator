import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:personal_cv/model/academic.dart';
import 'package:personal_cv/model/course.dart';
import 'package:personal_cv/model/skill.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/util/gemini_helper.dart';
import 'package:personal_cv/util/string_display.dart';
import 'package:personal_cv/widget/data_input/array_input.dart';
import 'package:personal_cv/widget/data_input/date_input.dart';
import 'package:personal_cv/widget/dialog.dart';
import 'package:personal_cv/widget/gemini.dart';
import 'package:provider/provider.dart';

class AcademicTile extends StatelessWidget {
  final Academic academic;
  final void Function() onEdit;
  final void Function() onDelete;
  const AcademicTile(
      {super.key,
      required this.academic,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stringConversion(academic.school, 'School Missing'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            "${stringConversion(academic.degree, 'Degree Missing')}, ${stringConversion(academic.field, 'Field Missing')}",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
              '${stringConversion(academic.startDate, 'Start Date Missing')} - ${stringConversion(academic.endDate, 'End Date Missing')}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.3, letterSpacing: 1.2)),
          Text(
            'Skills: ${academic.skills.map(
                  (e) => e.skill,
                ).join(', ')}',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(letterSpacing: 1.2),
          ),
          Text(
            'Courses: ${academic.courses.map(
                  (e) => e.title,
                ).join(', ')}',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(letterSpacing: 1.2),
          ),
        ],
      ),
      subtitle: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 3),
          borderRadius: const BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        constraints: const BoxConstraints(maxHeight: 300),
        padding: const EdgeInsets.all(5),
        child: SingleChildScrollView(
          child: Text(academic.description),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Remove',
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}

class AcademicInputDialog extends StatefulWidget {
  final int? index;
  final Academic? academic;
  const AcademicInputDialog({super.key, this.index, this.academic});

  @override
  State<AcademicInputDialog> createState() => _AcademicInputDialogState();
}

class _AcademicInputDialogState extends State<AcademicInputDialog> {
  final _formKey = GlobalKey<FormState>();

  bool addMode = true;

  final TextEditingController _schoolTextController = TextEditingController();
  final TextEditingController _degreeTextController = TextEditingController();
  final TextEditingController _fieldTextController = TextEditingController();
  final TextEditingController _startDateTextController =
      TextEditingController();
  final TextEditingController _endDateTextController = TextEditingController();

  List<Skill> _skills = [];
  List<Course> _courses = [];
  final TextEditingController _descriptionTextController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    addMode = (widget.index == null || widget.academic == null);
    _schoolTextController.text = widget.academic?.school ?? '';
    _degreeTextController.text = widget.academic?.degree ?? '';
    _fieldTextController.text = widget.academic?.field ?? '';
    _startDateTextController.text = widget.academic?.startDate ?? '';
    _endDateTextController.text = widget.academic?.endDate ?? '';
    _skills = widget.academic?.skills ?? [];
    _courses = widget.academic?.courses ?? [];
    _descriptionTextController.text = widget.academic?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${(addMode) ? 'Create' : 'Edit'} Education'),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
            maxWidth: 1080,
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const LoadingDialogBody(
                              text: 'Loading and analyzing the information');
                        });
                    pickAndConvertFilesToDataParts(context).then((dataParts) {
                      final Iterable<Part> newList = List.from([
                        TextPart('''
Retrieve the following information and return in strict json format without other text. If the information not found, fill with null.
1. School Name (key: school) // In full name
2. Degree (key: degree)
3. Field Of Study  (key: field)
4. Start Date (key: startDate, format: MMMM YYYY)
5. End Date (key: endDate, format: MMMM YYYY)
6. Courses (key: courses) //The list of courses studied
6. Skills (key: skills) //The list of skills learnt from the courses
7. Description (key: description) // Generate a report for the study, what and how it is done.

Strict json format as follows is needed.
{
  "school": "",
  "degree": "",
  "field": "",
  "startDate": "",
  "endDate": "",
  "courses": [],
  "skills": [],
  "description": ""
}
''')
                      ])
                        ..addAll(dataParts);
                      if (dataParts.isEmpty) {
                        throw Exception('No files selected');
                      }
                      return geminiResponse(
                              context: context,
                              prompt: [Content.multi(newList)],
                              responseMimeType: 'application/json')
                          .then((response) {
                        if (response.text == null) {
                          throw Exception('Empty respoonse');
                        }
                        Navigator.of(context).pop();
                        try {
                          Map<String, dynamic> data =
                              jsonDecode(response.text!);
                          _schoolTextController.text =
                              data['school'] ?? 'Not found';
                          _degreeTextController.text =
                              data['degree'] ?? 'Not found';
                          _fieldTextController.text =
                              data['field'] ?? 'Not found';
                          _startDateTextController.text =
                              data['startDate'] ?? '';
                          _endDateTextController.text = data['endDate'] ?? '';
                          _descriptionTextController.text =
                              data['description'] ?? 'Not found';

                          setState(
                            () {
                              _skills = List.from(data['skills'])
                                  .map((data) => Skill(skill: data))
                                  .toList();
                              _courses = List.from(data['courses'])
                                  .map((data) => Course(title: data))
                                  .toList();
                            },
                          );
                        } catch (e) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return GeminiRawResponse(
                                response: response.text ?? 'null',
                              );
                            },
                          );
                        }
                      });
                    }).catchError((error) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error getting files: $error')),
                      );
                    });
                  },
                  child: const Text('Import From Transcript'),
                ),
                ListTile(
                  title: const Text('School *'),
                  subtitle: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input school name';
                      }
                      return null;
                    },
                    controller: _schoolTextController,
                  ),
                ),
                ListTile(
                  title: const Text('Degree *'),
                  subtitle: TextFormField(
                    decoration: const InputDecoration(
                      label: Text('Ex: Bachelor'),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input degree';
                      }
                      return null;
                    },
                    controller: _degreeTextController,
                  ),
                ),
                ListTile(
                  title: const Text('Field of Study *'),
                  subtitle: TextFormField(
                    decoration: const InputDecoration(
                      label: Text('Ex: Engineering'),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input the field';
                      }
                      return null;
                    },
                    controller: _fieldTextController,
                  ),
                ),
                ListTile(
                  title: const Text('Start Date *'),
                  subtitle: MonthYearPickerFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input the start date';
                      }
                      return null;
                    },
                    controller: _startDateTextController,
                  ),
                ),
                ListTile(
                  title: const Text('End Date * (Or expected)'),
                  subtitle: MonthYearPickerFormField(
                    onChanged: (date) {},
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input the end date';
                      }
                      return null;
                    },
                    controller: _endDateTextController,
                  ),
                ),
                ListTile(
                  title: const Text('Skills *'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(left: 5, right: 20),
                    child: ArrayInput(
                      key: UniqueKey(),
                      itemName: 'Skill',
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                      initial: _skills.map((e) => e.skill).toList(),
                      onChanged: (items) {
                        _skills = items.map((e) => Skill(skill: e)).toList();
                      },
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Courses *'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(left: 5, right: 20),
                    child: ArrayInput(
                      key: UniqueKey(),
                      itemName: 'Course',
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                      initial: _courses.map((e) => e.title).toList(),
                      onChanged: (items) {
                        _courses = items
                            .map((e) => Course(
                                title: e, location: _schoolTextController.text))
                            .toList();
                      },
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Description *'),
                  subtitle: GeminiDescriptionHelperInput(
                    aspect: 'Education',
                    controller: _descriptionTextController,
                    generatePromote: () {
                      if (_schoolTextController.text.isEmpty ||
                          _degreeTextController.text.isEmpty ||
                          _fieldTextController.text.isEmpty ||
                          _startDateTextController.text.isEmpty ||
                          _endDateTextController.text.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              ConfirmationDialogBody(
                            text:
                                'Please provide all the information above before using generate function.',
                            actionButtons: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                        return null;
                      }
                      return '''Given the following information.
                    School: ${_schoolTextController.text}
                    Degree: ${_degreeTextController.text}
                    Field of Study: ${_fieldTextController.text}
                    Start Date: ${_startDateTextController.text}
                    End Date: ${_endDateTextController.text}
                    Courses: ${_courses.map((e) => e.title).join(', ')}
                    Skills: ${_skills.join(', ')}
                    1. Generate and create a description of my education with the content of what I did, how I did, and why I did.
                    2. Return in point form. 
                    3. Do not response with the provided information.
                    4. Do not response with introduction and closure phrase.''';
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input the description';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            for (Course e in _courses) {
              e.location = _schoolTextController.text;
            }
            Academic academic = Academic(
                school: _schoolTextController.text,
                degree: _degreeTextController.text,
                field: _fieldTextController.text,
                startDate: _startDateTextController.text,
                endDate: _endDateTextController.text,
                skills: _skills,
                courses: _courses,
                description: _descriptionTextController.text);
            if (addMode) {
              Provider.of<DataProvider>(context, listen: false)
                  .addAcademic(academic);
              Navigator.of(context).pop();
            } else {
              Provider.of<DataProvider>(context, listen: false)
                  .editAcademic(widget.index!, academic);
              Navigator.of(context).pop();
            }
          },
          child: Text((addMode) ? 'Create' : 'Edit'),
        ),
      ],
    );
  }
}
