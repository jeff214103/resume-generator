import 'package:flutter/material.dart';
import 'package:personal_cv/model/language.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/util/string_display.dart';
import 'package:provider/provider.dart';

class LanguageTile extends StatelessWidget {
  final Language language;
  final void Function() onEdit;
  final void Function() onDelete;
  const LanguageTile(
      {super.key,
      required this.language,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        stringConversion(language.language, 'Language Missing'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      subtitle: Text(
        stringConversion(language.proficiency, 'Proficiency Missing'),
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

class LanguageInputDialog extends StatefulWidget {
  final int? index;
  final Language? language;
  const LanguageInputDialog({super.key, this.index, this.language});

  @override
  State<LanguageInputDialog> createState() => _LanguageInputDialogState();
}

class _LanguageInputDialogState extends State<LanguageInputDialog> {
  final _formKey = GlobalKey<FormState>();

  bool addMode = true;

  final TextEditingController _languageTextController = TextEditingController();
  String? _proficiency;

  @override
  void initState() {
    super.initState();
    addMode = (widget.index == null || widget.language == null);
    _languageTextController.text = widget.language?.language ?? '';
    String? proficiency = widget.language?.proficiency;
    _proficiency = (proficiency == null || proficiency.isEmpty)
        ? null
        : widget.language?.proficiency;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${(addMode) ? 'Create' : 'Edit'} Languages'),
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
                  title: const Text('Language *'),
                  subtitle: TextFormField(
                    controller: _languageTextController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input the language title';
                      }
                      return null;
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Proficiency *'),
                  subtitle: DropdownButtonFormField(
                    value: _proficiency,
                    hint: const Text(
                      'Please Select',
                    ),
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _proficiency = value;
                      });
                    },
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Need to choose employment type";
                      }
                      return null;
                    },
                    items: [
                      'Fundamental',
                      'Novice',
                      'Intermediate',
                      'Advanced',
                      'Expert',
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

            Language language = Language(
              language: _languageTextController.text,
              proficiency: _proficiency!,
            );
            if (addMode) {
              Provider.of<DataProvider>(context, listen: false)
                  .addLanguage(language);
              Navigator.of(context).pop();
            } else {
              Provider.of<DataProvider>(context, listen: false)
                  .editLanguage(widget.index!, language);
              Navigator.of(context).pop();
            }
          },
          child: Text((addMode) ? 'Create' : 'Edit'),
        ),
      ],
    );
  }
}
