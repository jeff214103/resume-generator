import 'package:flutter/material.dart';
import 'package:personal_cv/model/award.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/util/string_display.dart';
import 'package:personal_cv/widget/data_input/date_input.dart';
import 'package:personal_cv/widget/dialog.dart';
import 'package:personal_cv/widget/gemini.dart';
import 'package:provider/provider.dart';

class AwardTile extends StatelessWidget {
  final Award award;
  final void Function() onEdit;
  final void Function() onDelete;
  const AwardTile(
      {super.key,
      required this.award,
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
            stringConversion(award.title, 'Title Missing'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            stringConversion(award.issuer, 'Issuer Missing'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(stringConversion(award.issueDate, 'Issue Date Missing'),
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
          child: Text(stringConversion(award.description, 'Award Missing')),
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

class AwardInputDialog extends StatefulWidget {
  final int? index;
  final Award? award;
  const AwardInputDialog({super.key, this.index, this.award});

  @override
  State<AwardInputDialog> createState() => _AwardInputDialogState();
}

class _AwardInputDialogState extends State<AwardInputDialog> {
  final _formKey = GlobalKey<FormState>();

  bool addMode = true;

  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _issuerTextController = TextEditingController();
  final TextEditingController _issueDateTextController =
      TextEditingController();
  final TextEditingController _descriptionTextController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    addMode = (widget.index == null || widget.award == null);
    _titleTextController.text = widget.award?.title ?? '';
    _issuerTextController.text = widget.award?.issuer ?? '';
    _issueDateTextController.text = widget.award?.issueDate ?? '';
    _descriptionTextController.text = widget.award?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${(addMode) ? 'Create' : 'Edit'} Award'),
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
                        return 'Please input the award title';
                      }
                      return null;
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Issuer *'),
                  subtitle: TextFormField(
                    controller: _issuerTextController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input issuer';
                      }
                      return null;
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Issue Date'),
                  subtitle: MonthYearPickerFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select issue date';
                      }
                      return null;
                    },
                    controller: _issueDateTextController,
                  ),
                ),
                ListTile(
                  title: const Text('Description'),
                  subtitle: GeminiDescriptionHelperInput(
                    aspect: 'Award and Achievement',
                    controller: _descriptionTextController,
                    generatePromote: () {
                      if (_titleTextController.text.isEmpty ||
                          _issuerTextController.text.isEmpty ||
                          _issueDateTextController.text.isEmpty) {
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
                      return '''Given the following information of award and achievement.
                    Tile: ${_titleTextController.text}
                    Issuer: ${_issuerTextController.text}
                    Issue Date: ${_issueDateTextController.text}
                    1. Generate and create a description of the award.
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

            Award award = Award(
                title: _titleTextController.text,
                issuer: _issuerTextController.text,
                issueDate: _issueDateTextController.text,
                description: _descriptionTextController.text);
            if (addMode) {
              Provider.of<DataProvider>(context, listen: false).addAward(award);
              Navigator.of(context).pop();
            } else {
              Provider.of<DataProvider>(context, listen: false)
                  .editAward(widget.index!, award);
              Navigator.of(context).pop();
            }
          },
          child: Text((addMode) ? 'Create' : 'Edit'),
        ),
      ],
    );
  }
}
