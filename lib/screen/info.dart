import 'package:flutter/material.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:provider/provider.dart';

class InformationPage extends StatelessWidget {
  final String title;
  final List<dynamic> data;
  final Widget addDialog;
  final Widget Function(BuildContext context, int index) tileBuilder;
  const InformationPage(
      {super.key,
      required this.title,
      required this.data,
      required this.addDialog,
      required this.tileBuilder});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Resume Generator'.toUpperCase()),
        ),
        body: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Center(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                  title: Text(title.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                ),
              ),
            ),
            Expanded(
              child: (data.isEmpty)
                  ? SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'There is no ${title.toLowerCase()}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          FilledButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => addDialog,
                              );
                            },
                            child: const Text('Add Data'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 50),
                      itemCount: data.length,
                      itemBuilder: (BuildContext context, int index) {
                        return tileBuilder(context, index);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add Record',
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) => addDialog,
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
