import 'package:flutter/material.dart';
import 'package:personal_cv/model/skill.dart';
import 'package:personal_cv/model/workexp.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/widget/data_input/array_input.dart';
import 'package:personal_cv/widget/data_input/date_input.dart';
import 'package:personal_cv/widget/dialog.dart';
import 'package:personal_cv/widget/gemini.dart';
import 'package:provider/provider.dart';

class WorkExperienceTile extends StatelessWidget {
  final WorkExperience workExperience;
  final void Function() onEdit;
  final void Function() onDelete;
  const WorkExperienceTile(
      {super.key,
      required this.workExperience,
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
            workExperience.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            workExperience.companyName,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            workExperience.employmentType,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text('${workExperience.startDate} - ${workExperience.endDate}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.3, letterSpacing: 1.2)),
          Text(
            workExperience.location,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(height: 1.3, letterSpacing: 1.2),
          ),
          Text(
            'Skills: ${workExperience.skills.map(
                  (e) => e.skill,
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
          child: Text(workExperience.description),
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

class WorkExperienceInputDialog extends StatefulWidget {
  final int? index;
  final WorkExperience? workExperience;
  const WorkExperienceInputDialog({super.key, this.index, this.workExperience});

  @override
  State<WorkExperienceInputDialog> createState() =>
      _WorkExperienceInputDialogState();
}

class _WorkExperienceInputDialogState extends State<WorkExperienceInputDialog> {
  final _formKey = GlobalKey<FormState>();

  bool addMode = true;

  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _companyNameTextController =
      TextEditingController();
  String? _employmentType;
  final TextEditingController _locationTextController = TextEditingController();
  final TextEditingController _startDateTextController =
      TextEditingController();
  final TextEditingController _endDateTextController = TextEditingController();
  bool endDateNow = false;
  List<Skill> _skills = [];
  final TextEditingController _descriptionTextController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    addMode = (widget.index == null || widget.workExperience == null);
    _titleTextController.text = widget.workExperience?.title ?? '';
    _companyNameTextController.text = widget.workExperience?.companyName ?? '';
    _employmentType = widget.workExperience?.employmentType;
    _locationTextController.text = widget.workExperience?.location ?? '';
    _startDateTextController.text = widget.workExperience?.startDate ?? '';
    _endDateTextController.text = widget.workExperience?.endDate ?? '';
    endDateNow = (_endDateTextController.text == 'Now');
    _skills = widget.workExperience?.skills ?? [];
    _descriptionTextController.text = widget.workExperience?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${(addMode) ? 'Create' : 'Edit'} Work Experience'),
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
                ListTile(
                  title: const Text('Title *'),
                  subtitle: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input work title';
                      }
                      return null;
                    },
                    controller: _titleTextController,
                  ),
                ),
                ListTile(
                  title: const Text('Company Name *'),
                  subtitle: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input company name';
                      }
                      return null;
                    },
                    controller: _companyNameTextController,
                  ),
                ),
                ListTile(
                  title: const Text('Employment Type *'),
                  subtitle: DropdownButtonFormField(
                    value: _employmentType,
                    hint: const Text(
                      'Please Select',
                    ),
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _employmentType = value;
                      });
                    },
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Need to choose employment type";
                      }
                      return null;
                    },
                    items: [
                      'Self-Employed',
                      'Freelance',
                      'Internship',
                      'Apprenticeship',
                      'Contract Full-time',
                      'Permanent Part-time',
                      'Contract Part-time',
                      'Casual / On-call',
                      'Seasonal',
                      'Permanent Full-time',
                      'Co-op'
                    ].map(
                      (String val) {
                        return DropdownMenuItem(
                          value: val,
                          child: Text(
                            val,
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
                ListTile(
                  title: const Text('Location *'),
                  subtitle: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input the location';
                      }
                      return null;
                    },
                    controller: _locationTextController,
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
                CheckboxListTile(
                  value: endDateNow,
                  onChanged: (value) {
                    setState(() {
                      endDateNow = value!;
                      if (endDateNow == true) {
                        _endDateTextController.text = 'Now';
                      } else {
                        _endDateTextController.text = '';
                      }
                    });
                  },
                  title:
                      const Text('End Date * (Checked to be current position)'),
                  controlAffinity: ListTileControlAffinity.trailing,
                  subtitle: MonthYearPickerFormField(
                    onChanged: (date) {
                      if (date != null) {
                        setState(() {
                          endDateNow = false;
                        });
                      }
                    },
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
                  subtitle: ArrayInput(
                    itemName: 'Skill',
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                    initial: _skills.map((e) => e.skill).toList(),
                    onChanged: (items) {
                      _skills = items.map((e) => Skill(skill: e)).toList();
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Description *'),
                  subtitle: GeminiDescriptionHelperInput(
                    aspect: 'Work Experience',
                    controller: _descriptionTextController,
                    generatePromote: () {
                      if (_titleTextController.text.isEmpty ||
                          _companyNameTextController.text.isEmpty ||
                          _employmentType == null ||
                          _employmentType!.isEmpty ||
                          _locationTextController.text.isEmpty ||
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
                    Job Title: ${_titleTextController.text}
                    Company Name: ${_companyNameTextController.text}
                    Employment Type: $_employmentType
                    Location: ${_locationTextController.text}
                    Start Date: ${_startDateTextController.text}
                    End Date: ${_endDateTextController.text}
                    Skills: ${_skills.map((e) => e.skill).join(', ')}
                    1. Generate and create a description of my work with the content of what I did, how I did, and why I did.
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
            WorkExperience workExperience = WorkExperience(
                title: _titleTextController.text,
                employmentType: _employmentType!,
                companyName: _companyNameTextController.text,
                location: _locationTextController.text,
                startDate: _startDateTextController.text,
                endDate: _endDateTextController.text,
                skills: _skills,
                description: _descriptionTextController.text);
            if (addMode) {
              Provider.of<DataProvider>(context, listen: false)
                  .addWorkExperience(workExperience);
              Navigator.of(context).pop();
            } else {
              Provider.of<DataProvider>(context, listen: false)
                  .editWorkExperience(widget.index!, workExperience);
              Navigator.of(context).pop();
            }
          },
          child: Text((addMode) ? 'Create' : 'Edit'),
        ),
      ],
    );
  }
}
