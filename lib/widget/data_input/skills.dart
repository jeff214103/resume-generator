import 'package:flutter/material.dart';
import 'package:personal_cv/model/skill.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/widget/data_input/array_input.dart';
import 'package:provider/provider.dart';

class SkillDialog extends StatefulWidget {
  final List<Skill>? initialSkill;
  const SkillDialog({super.key, this.initialSkill});

  @override
  State<SkillDialog> createState() => _SkillDialogState();
}

class _SkillDialogState extends State<SkillDialog> {
  List<Skill> _skills = [];
  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.initialSkill ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Skills List'),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
            maxWidth: 1080,
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: ListTile(
          title: const Text('Skills *'),
          subtitle: LayoutBuilder(
            builder: (context, constraints) => ArrayInput(
              maxHeight: constraints.maxHeight - 20,
              itemName: 'Skill',
              initial: _skills.map((e) => e.skill).toList(),
              onChanged: (items) {
                _skills = items.map((e) => Skill(skill: e)).toList();
              },
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
            Provider.of<DataProvider>(context, listen: false)
                .overwriteSkill(_skills);

            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
