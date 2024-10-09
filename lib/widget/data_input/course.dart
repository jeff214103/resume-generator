import 'package:flutter/material.dart';
import 'package:personal_cv/model/course.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/util/string_display.dart';
import 'package:personal_cv/widget/data_input/date_input.dart';
import 'package:personal_cv/widget/dialog.dart';
import 'package:personal_cv/widget/gemini.dart';
import 'package:provider/provider.dart';

class CourseTile extends StatelessWidget {
  final Course course;
  final void Function() onEdit;
  final void Function() onDelete;
  const CourseTile(
      {super.key,
      required this.course,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: (course.description == null) ? false : true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stringConversion(course.title, 'Title Missing'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            stringConversion(course.location, 'Location Missing'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
              '${(course.startDate == null) ? '' : '${course.startDate}'}${(course.duration == null) ? '' : ', ${course.duration}'}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.3, letterSpacing: 1.2)),
        ],
      ),
      subtitle: (course.description == null)
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border.all(width: 3),
                borderRadius: const BorderRadius.all(
                  Radius.circular(5),
                ),
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              padding: const EdgeInsets.all(5),
              child: SingleChildScrollView(
                child: Text(course.description ?? '-'),
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

class CourseInputDialog extends StatefulWidget {
  final int? index;
  final Course? course;
  const CourseInputDialog({super.key, this.index, this.course});

  @override
  State<CourseInputDialog> createState() => _CourseInputDialogState();
}

class _CourseInputDialogState extends State<CourseInputDialog> {
  final _formKey = GlobalKey<FormState>();

  bool addMode = true;

  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _locationTextController = TextEditingController();
  final TextEditingController _startDateTextController =
      TextEditingController();
  final TextEditingController _durationTextController = TextEditingController();
  final TextEditingController _descriptionTextController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    addMode = (widget.index == null || widget.course == null);
    _titleTextController.text = widget.course?.title ?? '';
    _locationTextController.text = widget.course?.location ?? '';
    _startDateTextController.text = widget.course?.startDate ?? '';
    _durationTextController.text = widget.course?.duration ?? '';
    _descriptionTextController.text = widget.course?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${(addMode) ? 'Create' : 'Edit'} Courses & Projects'),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
            maxWidth: 1080,
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(child: Column(
            children: [
              ListTile(
                title: const Text('Title *'),
                subtitle: TextFormField(
                  controller: _titleTextController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please input the course title';
                    }
                    return null;
                  },
                ),
              ),
              ListTile(
                title: const Text('Location *'),
                subtitle: TextFormField(
                  controller: _locationTextController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please input location';
                    }
                    return null;
                  },
                ),
              ),
              ListTile(
                title: const Text('Start Date'),
                subtitle: MonthYearPickerFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please start date';
                    }
                    return null;
                  },
                  controller: _startDateTextController,
                ),
              ),
              ListTile(
                title: const Text('Duration'),
                subtitle: TextFormField(
                  controller: _durationTextController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please input duration';
                    }
                    return null;
                  },
                ),
              ),
              ListTile(
                title: const Text('Description'),
                subtitle: GeminiDescriptionHelperInput(
                  aspect: 'Course and Project',
                  controller: _descriptionTextController,
                  generatePromote: () {
                    if (_titleTextController.text.isEmpty ||
                        _locationTextController.text.isEmpty ||
                        _startDateTextController.text.isEmpty ||
                        _durationTextController.text.isEmpty) {
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
                    Tile: ${_titleTextController.text}
                    Location: ${_locationTextController.text}
                    Start Date: ${_startDateTextController.text}
                    Duration: ${_durationTextController.text}
                    1. Generate and create a description of the course or project with the content of what I expected to learn, done, or achievement.
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
        ),),
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

            Course course = Course(
                title: _titleTextController.text,
                location: _locationTextController.text,
                startDate: _startDateTextController.text,
                duration: _durationTextController.text,
                description: _descriptionTextController.text);
            if (addMode) {
              Provider.of<DataProvider>(context, listen: false)
                  .addCourse(course);
              Navigator.of(context).pop();
            } else {
              Provider.of<DataProvider>(context, listen: false)
                  .editCourse(widget.index!, course);
              Navigator.of(context).pop();
            }
          },
          child: Text((addMode) ? 'Create' : 'Edit'),
        ),
      ],
    );
  }
}
