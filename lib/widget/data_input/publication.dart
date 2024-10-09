import 'package:flutter/material.dart';
import 'package:personal_cv/model/publication.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/util/string_display.dart';
import 'package:personal_cv/widget/data_input/date_input.dart';
import 'package:personal_cv/widget/dialog.dart';
import 'package:personal_cv/widget/gemini.dart';
import 'package:provider/provider.dart';

class PublicationTile extends StatelessWidget {
  final Publication publication;
  final void Function() onEdit;
  final void Function() onDelete;
  const PublicationTile(
      {super.key,
      required this.publication,
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
            stringConversion(publication.title, 'Title Missing'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            stringConversion(publication.publication, 'Publication Missing'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(stringConversion(publication.date, 'Date Missing'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.3, letterSpacing: 1.2)),
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
          child: Text(publication.description),
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

class PublicationInputDialog extends StatefulWidget {
  final int? index;
  final Publication? publication;
  const PublicationInputDialog({super.key, this.index, this.publication});

  @override
  State<PublicationInputDialog> createState() => _PublicationInputDialogState();
}

class _PublicationInputDialogState extends State<PublicationInputDialog> {
  final _formKey = GlobalKey<FormState>();

  bool addMode = true;

  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _publicationTextController =
      TextEditingController();
  final TextEditingController _dateTextController = TextEditingController();
  final TextEditingController _descriptionTextController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    addMode = (widget.index == null || widget.publication == null);
    _titleTextController.text = widget.publication?.title ?? '';
    _publicationTextController.text = widget.publication?.publication ?? '';
    _dateTextController.text = widget.publication?.date ?? '';
    _descriptionTextController.text = widget.publication?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${(addMode) ? 'Create' : 'Edit'} Publication'),
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
                    controller: _titleTextController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input the publication title';
                      }
                      return null;
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Publication *'),
                  subtitle: TextFormField(
                    controller: _publicationTextController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input publication';
                      }
                      return null;
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Date *'),
                  subtitle: MonthYearPickerFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select publication date';
                      }
                      return null;
                    },
                    controller: _dateTextController,
                  ),
                ),
                ListTile(
                  title: const Text('Description *'),
                  subtitle: GeminiDescriptionHelperInput(
                    aspect: 'Publication',
                    controller: _descriptionTextController,
                    generatePromote: () {
                      if (_titleTextController.text.isEmpty ||
                          _publicationTextController.text.isEmpty ||
                          _dateTextController.text.isEmpty) {
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
                      return '''Given the following information of publication.
                    Tile: ${_titleTextController.text}
                    Publication: ${_publicationTextController.text}
                    Publish date: ${_dateTextController.text}
                    1. Generate and create a description of the publication.
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

            Publication publication = Publication(
                title: _titleTextController.text,
                publication: _publicationTextController.text,
                date: _dateTextController.text,
                description: _descriptionTextController.text);
            if (addMode) {
              Provider.of<DataProvider>(context, listen: false)
                  .addPublication(publication);
              Navigator.of(context).pop();
            } else {
              Provider.of<DataProvider>(context, listen: false)
                  .editPublication(widget.index!, publication);
              Navigator.of(context).pop();
            }
          },
          child: Text((addMode) ? 'Create' : 'Edit'),
        ),
      ],
    );
  }
}
