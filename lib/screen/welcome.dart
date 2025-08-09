import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:provider/provider.dart';

List<Map<String, dynamic>> items = [
  {
    "id": 1,
    "header": "Welcome",
    "description":
        "The app provides you an easy platform for generating custom made resume content.",
    "image": "assets/images/1.png"
  },
  {
    "id": 2,
    "header": "Privacy",
    "description":
        "You are responsible for your data. All your personal data is stored in your local devices. Your data will send to Google Gemini API for improvement and generation.  The developer of the app will not responsible for any data leakage because of your device securities and Google Gemini Error.",
    "image": "assets/images/2.png"
  },
  {
    "id": 3,
    "header": "Input",
    "description":
        "First you may fill your background information including education, work experiences, activities, achievement, and more.  Do not afraid to over input informaiton, as the information will soon be filtered and used for generating a custom made resume.",
    "image": "assets/images/3.png"
  },
  {
    "id": 4,
    "header": "Generation",
    "description":
        "By providing the jobs ads/description, custom made resume fullfilling the job requirements completely base on your background information input.  The process of generation will send your data to Google Gemini API. All the procedure will follow to Google standard.",
    "image": "assets/images/4.png"
  },
  {
    "id": 5,
    "header": "Author",
    "description":
        "The code will be open source on github. Feel free to contribute to the project, and wish your best in job hunting. \nIf you feel the app is good, you can choose to buy me a coffee!",
    "image": "assets/images/5.png",
    "link": [
      {
        "name": "github",
        "url": "https://github.com/jeff214103/resume-generator",
      },
      {
        "name": "about author",
        "url": "https://jeff214103.github.io/personal-webpage/",
      },
    ],
    // Replace with the actual GitHub repository link
  },
  {
    "id": 6,
    "header": "Almost There",
    "description": "Start using the application.",
    "image": "assets/images/6.png"
  },
];

class WelcomeScreen extends StatefulWidget {
  final bool allowSkip;
  const WelcomeScreen({super.key, required this.allowSkip});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<Widget> indicator() => List<Widget>.generate(
        items.length,
        (index) => GestureDetector(
          onTap: () {
            _pageViewController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3.0),
            height: 10.0,
            width: 10.0,
            decoration: BoxDecoration(
                color: currentPage.round() == index
                    ? const Color(0XFF256075)
                    : const Color(0XFF256075).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.0)),
          ),
        ),
      );

  double currentPage = 0.0;
  final PageController _pageViewController = PageController();

  @override
  void initState() {
    super.initState();
    _pageViewController.addListener(() {
      setState(() {
        currentPage = _pageViewController.page ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageViewController,
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              return WelcomePageLayout(
                header: items[index]['header'],
                description: items[index]['description'],
                link: items[index]['link'],
                image: items[index]['image'],
                onFinish: (index == items.length - 1)
                    ? () {
                        Navigator.of(context).pop();
                      }
                    : null,
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 70.0),
              padding:
                  const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: (currentPage != items.length - 1)
                        ? (widget.allowSkip == true)
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('SKIP'),
                              )
                            : null
                        : ElevatedButton(
                            onPressed: () {
                              _pageViewController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text('Back'),
                          ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: indicator(),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: FilledButton(
                      onPressed: () {
                        if (currentPage != items.length - 1) {
                          _pageViewController.animateToPage(
                            currentPage.toInt() + 1,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                          (currentPage != items.length - 1) ? 'NEXT' : 'GO'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomePageLayout extends StatelessWidget {
  final String? image;
  final List<Map<String, String>>? link;
  final String header;
  final String description;
  final void Function()? onFinish;
  const WelcomePageLayout(
      {super.key,
      this.image,
      this.link,
      required this.header,
      required this.description,
      this.onFinish});

  List<Widget> buildLinks(List<Map<String, String>> links) {
    return [
      for (final link in links)
        Center(
          child: Link(
            uri: Uri.tryParse(link['url'] ?? ''),
            target: LinkTarget.blank,
            builder: (context, followLink) => TextButton(
              onPressed: followLink,
              child: Text(link['name'] ?? ''),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: (image == null)
                ? Container(
                    color: Colors.red,
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.3,
                    constraints: const BoxConstraints(maxWidth: 700),
                  )
                : Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height * 0.3,
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Image.asset(
                      image!,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                children: <Widget>[
                  Text(header,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(height: 2)),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.3, letterSpacing: 1.2),
                    textAlign: TextAlign.center,
                  ),
                  if (link != null)
                    Wrap(
                      children: buildLinks(link!),
                    ),
                  if (onFinish != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: FilledButton(
                          onPressed: onFinish,
                          child: const Text('Get Started')),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Resume Generator!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'It looks like you\'re new here. You can:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildOption(
                context,
                icon: Icons.upload_file,
                title: 'Import from any file',
                description:
                    'Import your resume or CV from a PDF, DOCX, or other text-based file. Examples:\n1. Current Resume\n2. Linkedin Export PDF\n3. Profiles',
                onTap: () {
                  dataProvider.importAdvance(context).then((value) {
                    if (value != true) return;
                    Navigator.of(context).pop();
                  });
                },
              ),
              _buildOption(
                context,
                icon: Icons.insert_drive_file,
                title: 'Import from exported JSON',
                description:
                    'Restore your data from a previously exported Resume Generator JSON file',
                onTap: () {
                  dataProvider.importData(context).then((value) {
                    if (value != true) return;
                    Navigator.of(context).pop();
                  });
                },
              ),
              _buildOption(
                context,
                icon: Icons.edit_note,
                title: 'Start from scratch',
                description: 'Manually enter your information',
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Or if you prefer, you can close this dialog and start adding information manually using the + buttons.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
