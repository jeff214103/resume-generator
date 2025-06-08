import 'package:flutter/material.dart';
import 'package:personal_cv/model/academic.dart';
import 'package:personal_cv/model/activities.dart';
import 'package:personal_cv/model/award.dart';
import 'package:personal_cv/model/course.dart';
import 'package:personal_cv/model/language.dart';
import 'package:personal_cv/model/publication.dart';
import 'package:personal_cv/model/workexp.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/screen/generate.dart';
import 'package:personal_cv/screen/info.dart';
import 'package:personal_cv/screen/setting.dart';
import 'package:personal_cv/screen/welcome.dart';
import 'package:personal_cv/widget/data_import_widget.dart';
import 'package:personal_cv/widget/data_input/academic.dart';
import 'package:personal_cv/widget/data_input/activity.dart';
import 'package:personal_cv/widget/data_input/award.dart';
import 'package:personal_cv/widget/data_input/course.dart';
import 'package:personal_cv/widget/data_input/languages.dart';
import 'package:personal_cv/widget/data_input/publication.dart';
import 'package:personal_cv/widget/data_input/skills.dart';
import 'package:personal_cv/widget/data_input/work_experience.dart';
import 'package:personal_cv/widget/dialog.dart';
import 'package:personal_cv/widget/loading_hint.dart';
import 'package:provider/provider.dart';

void _redirectTo(BuildContext context, Widget widget,
    {void Function(dynamic)? callback}) {
  Navigator.of(context)
      .push(
    MaterialPageRoute(
      builder: (context) => widget,
    ),
  )
      .then((value) {
    if (callback != null) {
      callback(value);
    }
  });
}

Future<dynamic> confirmDeleteDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => ConfirmationDialogBody(
      text: 'Are you sure to remove the record?',
      actionButtons: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

void notImplemented(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) => ConfirmationDialogBody(
      text: 'Not Implemented',
      actionButtons: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Ok'),
        ),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future applicationLoaded;

  Future<void> configureApplication(BuildContext context) {
    DataProvider dataProvider =
        Provider.of<DataProvider>(context, listen: false);
    return dataProvider.init().then((_) {
      if (dataProvider.geminiModel == '' || dataProvider.geminiModel.isEmpty) {
        _redirectTo(
            context,
            const WelcomeScreen(
              allowSkip: false,
            ), callback: (_) {
          dataProvider.initGemini();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    applicationLoaded = configureApplication(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Resume Generator'.toUpperCase()),
        actions: [
          IconButton(
            tooltip: 'Help',
            onPressed: () {
              _redirectTo(
                  context,
                  const WelcomeScreen(
                    allowSkip: true,
                  ));
            },
            icon: const Icon(Icons.help),
          ),
        ],
      ),
      body: FutureBuilder(
        future: applicationLoaded,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            return const MainLayout();
          } else {
            return const LoadingHint(text: 'Loading data...');
          }
        },
      ),
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) => SizedBox(
        width: double.infinity,
        child: ListView(
          padding: EdgeInsets.zero,
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
                  title: Text('Hello!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                  subtitle: Text('Welcome back',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer)),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: DashboardCard(
                title: 'Generate',
                iconData: Icons.pending_actions,
                background: Theme.of(context).primaryColor,
                onTap: () {
                  _redirectTo(context, const GenerateScreen());
                },
              ),
            ),
            DashboardLayout(
              title: 'Your Background',
              widgets: [
                DashboardBadgeCard(
                  title: 'Work Experience',
                  label: Text(
                    dataProvider.backgroundInfo.workExperiences.length
                        .toString(),
                  ),
                  iconData: Icons.work,
                  background: Colors.deepOrange,
                  onTap: () {
                    _redirectTo(
                      context,
                      InformationPage(
                        title: 'Work Experiences',
                        data: dataProvider.backgroundInfo.workExperiences,
                        tileBuilder: (context, index) {
                          WorkExperience workExperience = dataProvider
                              .backgroundInfo.workExperiences[index];
                          return WorkExperienceTile(
                            workExperience: workExperience,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    WorkExperienceInputDialog(
                                  index: index,
                                  workExperience: workExperience,
                                ),
                              );
                            },
                            onDelete: () {
                              confirmDeleteDialog(context).then((value) {
                                if (value == true) {
                                  Provider.of<DataProvider>(context,
                                          listen: false)
                                      .deleteWorkExperience(index);
                                }
                              });
                            },
                          );
                        },
                        addDialog: const WorkExperienceInputDialog(),
                      ),
                    );
                  },
                ),
                DashboardBadgeCard(
                  title: 'Education',
                  label: Text(
                    dataProvider.backgroundInfo.academics.length.toString(),
                  ),
                  iconData: Icons.school,
                  background: Colors.blue,
                  onTap: () {
                    _redirectTo(
                      context,
                      InformationPage(
                        title: 'Education',
                        data: dataProvider.backgroundInfo.academics,
                        tileBuilder: (context, index) {
                          Academic academic =
                              dataProvider.backgroundInfo.academics[index];
                          return AcademicTile(
                            academic: academic,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    AcademicInputDialog(
                                  index: index,
                                  academic: academic,
                                ),
                              );
                            },
                            onDelete: () {
                              confirmDeleteDialog(context).then((value) {
                                if (value == true) {
                                  Provider.of<DataProvider>(context,
                                          listen: false)
                                      .deleteAcademice(index);
                                }
                              });
                            },
                          );
                        },
                        addDialog: const AcademicInputDialog(),
                      ),
                    );
                  },
                ),
                DashboardBadgeCard(
                  title: 'Skills',
                  label: Text(
                    dataProvider.backgroundInfo.skills.length.toString(),
                  ),
                  iconData: Icons.handyman,
                  background: Colors.green,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => SkillDialog(
                        initialSkill: dataProvider.backgroundInfo.skills,
                      ),
                    );
                  },
                ),
                DashboardBadgeCard(
                  title: 'Languages',
                  label: Text(
                    dataProvider.backgroundInfo.languages.length.toString(),
                  ),
                  iconData: Icons.language,
                  background: Colors.yellow[700]!,
                  onTap: () {
                    _redirectTo(
                      context,
                      InformationPage(
                        title: 'Languages',
                        data: dataProvider.backgroundInfo.languages,
                        tileBuilder: (context, index) {
                          Language language =
                              dataProvider.backgroundInfo.languages[index];
                          return LanguageTile(
                            language: language,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    LanguageInputDialog(
                                  index: index,
                                  language: language,
                                ),
                              );
                            },
                            onDelete: () {
                              confirmDeleteDialog(context).then((value) {
                                if (value == true) {
                                  Provider.of<DataProvider>(context,
                                          listen: false)
                                      .deleteLanguage(index);
                                }
                              });
                            },
                          );
                        },
                        addDialog: const LanguageInputDialog(),
                      ),
                    );
                  },
                ),
                DashboardBadgeCard(
                  title: 'Activities',
                  label: Text(
                    dataProvider.backgroundInfo.activities.length.toString(),
                  ),
                  iconData: Icons.local_activity,
                  background: Colors.deepOrange,
                  onTap: () {
                    _redirectTo(
                      context,
                      InformationPage(
                        title: 'Activities',
                        data: dataProvider.backgroundInfo.activities,
                        tileBuilder: (context, index) {
                          Activity activity =
                              dataProvider.backgroundInfo.activities[index];
                          return ActivityTile(
                            activity: activity,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    ActivityInputDialog(
                                  index: index,
                                  activity: activity,
                                ),
                              );
                            },
                            onDelete: () {
                              confirmDeleteDialog(context).then((value) {
                                if (value == true) {
                                  Provider.of<DataProvider>(context,
                                          listen: false)
                                      .deleteActivity(index);
                                }
                              });
                            },
                          );
                        },
                        addDialog: const ActivityInputDialog(),
                      ),
                    );
                  },
                ),
                DashboardBadgeCard(
                  title: 'Awards & Achievement',
                  label: Text(
                    dataProvider.backgroundInfo.awards.length.toString(),
                  ),
                  iconData: Icons.emoji_events,
                  background: Colors.blue,
                  onTap: () {
                    _redirectTo(
                      context,
                      InformationPage(
                        title: 'Awards and Achievements',
                        data: dataProvider.backgroundInfo.awards,
                        tileBuilder: (context, index) {
                          Award award =
                              dataProvider.backgroundInfo.awards[index];
                          return AwardTile(
                            award: award,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    AwardInputDialog(
                                  index: index,
                                  award: award,
                                ),
                              );
                            },
                            onDelete: () {
                              confirmDeleteDialog(context).then((value) {
                                if (value == true) {
                                  Provider.of<DataProvider>(context,
                                          listen: false)
                                      .deleteAward(index);
                                }
                              });
                            },
                          );
                        },
                        addDialog: const AwardInputDialog(),
                      ),
                    );
                  },
                ),
                DashboardBadgeCard(
                  title: 'Courses & Projects',
                  label: Text(
                    dataProvider.backgroundInfo.courses.length.toString(),
                  ),
                  iconData: Icons.login,
                  background: Colors.green,
                  onTap: () {
                    _redirectTo(
                      context,
                      InformationPage(
                        title: 'Courses & Projects',
                        data: dataProvider.backgroundInfo.courses,
                        tileBuilder: (context, index) {
                          Course course =
                              dataProvider.backgroundInfo.courses[index];
                          return CourseTile(
                            course: course,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    CourseInputDialog(
                                  index: index,
                                  course: course,
                                ),
                              );
                            },
                            onDelete: () {
                              confirmDeleteDialog(context).then((value) {
                                if (value == true) {
                                  Provider.of<DataProvider>(context,
                                          listen: false)
                                      .deleteCourse(index);
                                }
                              });
                            },
                          );
                        },
                        addDialog: const CourseInputDialog(),
                      ),
                    );
                  },
                ),
                DashboardBadgeCard(
                  title: 'Publications',
                  label: Text(
                    dataProvider.backgroundInfo.publications.length.toString(),
                  ),
                  iconData: Icons.menu_book,
                  background: Colors.yellow[700]!,
                  onTap: () {
                    _redirectTo(
                      context,
                      InformationPage(
                        title: 'Publications',
                        data: dataProvider.backgroundInfo.publications,
                        tileBuilder: (context, index) {
                          Publication publication =
                              dataProvider.backgroundInfo.publications[index];
                          return PublicationTile(
                            publication: publication,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    PublicationInputDialog(
                                  index: index,
                                  publication: publication,
                                ),
                              );
                            },
                            onDelete: () {
                              confirmDeleteDialog(context).then((value) {
                                if (value == true) {
                                  Provider.of<DataProvider>(context,
                                          listen: false)
                                      .deletePublication(index);
                                }
                              });
                            },
                          );
                        },
                        addDialog: const PublicationInputDialog(),
                      ),
                    );
                  },
                ),
              ],
            ),
            DashboardLayout(
              title: 'Action',
              widgets: [
                DashboardCard(
                  title: 'Export',
                  iconData: Icons.download,
                  background: Colors.deepOrange,
                  onTap: () {
                    dataProvider.exportData();
                  },
                ),
                DashboardCard(
                  title: 'Import',
                  iconData: Icons.file_upload,
                  background: Colors.blue,
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            ImportDialog(dataProvider: dataProvider));
                  },
                ),
                DashboardCard(
                  title: 'Clean',
                  iconData: Icons.delete_forever,
                  background: Colors.green,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => ConfirmationDialogBody(
                        text:
                            'Are you sure to clean all information? This action is irreversible!',
                        actionButtons: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ).then((value) {
                      if (value != true) {
                        return;
                      }
                      dataProvider.cleanAll();
                    });
                  },
                ),
                DashboardCard(
                  title: 'Setting',
                  iconData: Icons.settings,
                  background: Colors.yellow[700]!,
                  onTap: () {
                    _redirectTo(
                      context,
                      SettingPage(
                        dataProvider: dataProvider,
                      ),
                      callback: (value) {},
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardLayout extends StatelessWidget {
  final String title;
  final List<Widget> widgets;
  const DashboardLayout(
      {super.key, required this.title, required this.widgets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmallScreen = constraints.maxWidth < 400;
              final int crossAxisCount = (constraints.maxWidth < 600
                  ? 2
                  : (constraints.maxWidth / 200).floor());
              final double spacing = isSmallScreen
                  ? 8.0
                  : (constraints.maxWidth < 600 ? 10.0 : 40.0);
              final double childAspectRatio = isSmallScreen ? 1.2 : 1.0;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: widgets,
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashboardBadgeCard extends StatelessWidget {
  const DashboardBadgeCard({
    super.key,
    required this.title,
    required this.label,
    required this.iconData,
    required this.background,
    required this.onTap,
  });
  final String title;
  final Widget label;
  final IconData iconData;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title badge, ${label is Text ? (label as Text).data : ""} items',
      child: Badge(
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        label: label,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: DashboardCard(
            background: background,
            title: title,
            iconData: iconData,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.iconData,
    required this.background,
    required this.onTap,
  });
  final String title;
  final IconData iconData;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 5),
              color: Theme.of(context).shadowColor.withValues(alpha: .2),
              spreadRadius: 2,
              blurRadius: 5,
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
