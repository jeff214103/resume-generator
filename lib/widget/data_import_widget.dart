import 'package:flutter/material.dart';
import 'package:personal_cv/providers/data_provider.dart';

class ImportDialog extends StatelessWidget {
  final DataProvider dataProvider;
  const ImportDialog({super.key, required this.dataProvider});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1080),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Import From',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 200,
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: [
                  ImportOptionCard(
                    title: 'Export JSON',
                    iconData: Icons.download,
                    background: Colors.deepOrange,
                    onTap: () {
                      dataProvider.importData().then((value) {
                        if (value != true) {
                          return;
                        }
                        Navigator.of(context).pop();
                      });
                    },
                  ),
                  ImportOptionCard(
                    title: 'Any Files',
                    iconData: Icons.attach_file,
                    background: Colors.blue,
                    onTap: () {
                      dataProvider.importAdvance(context).then((value) {
                        if (value != true) {
                          return;
                        }
                        Navigator.of(context).pop();
                      });
                    },
                  ),
                ]
                    .map(
                      (e) => AspectRatio(
                        aspectRatio: 1,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: e),
                      ),
                    )
                    .toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 20, bottom: 5),
              child: Text(
                'Importing data will overwrite your existing data. Use this feature carefully.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportOptionCard extends StatelessWidget {
  const ImportOptionCard(
      {super.key,
      required this.title,
      required this.iconData,
      required this.background,
      required this.onTap});
  final String title;
  final IconData iconData;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                offset: const Offset(0, 5),
                color: Theme.of(context).shadowColor.withOpacity(.2),
                spreadRadius: 2,
                blurRadius: 5)
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}
