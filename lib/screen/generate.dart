import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/screen/welcome.dart';
import 'package:personal_cv/widget/gemini.dart';
import 'package:personal_cv/widget/loading_hint.dart';
import 'package:provider/provider.dart';

Future<ChatSession> generateResume(
    {required BuildContext context,
    required String cvType,
    required String requirement}) {
  String prompt = '';
  if (cvType == 'Job') {
    prompt = '''The resume target is to apply job.
    The requirements as the follows.
    '$requirement'
    Wait for my criteria in the next prompt before any action.
  ''';
  } else if (cvType == 'Academic') {
    prompt = '''The resume target is for academic requirements.
    The requirements as the follows.
    '$requirement'
    Wait for my criteria in the next prompt before any action.
  ''';
  } else {
    throw Exception('Unsupported resume type');
  }
  GenerativeModel model = GenerativeModel(
    model: Provider.of<DataProvider>(context, listen: false).geminiModel,
    apiKey: Provider.of<DataProvider>(context, listen: false).geminiAPIKey,
  );
  ChatSession chat = model.startChat();
  // return Future.value(chat);

  return chat
      .sendMessage(
    Content.text(
      '''
You are writing a resume.  Before starting, understand the background by looking into the json.
'${jsonEncode(Provider.of<DataProvider>(context, listen: false).backgroundInfo)}'
Wait for my instruction in the next prompt before any action.
            ''',
    ),
  )
      .then((_) {
    return chat.sendMessage(Content.text(prompt)).then((_) {
      return chat.sendMessage(Content.text('''
Finish writing your resume based on the following instruction
1. Prioritize and highlight the background information fulfill the requirement
2. Use the requirement keyword for the relvant background information elaboration
3. Tailoring for the Role
4. Everything base on given background information
5. Highlighting Preferred Qualifications
6. For work experience, write point in the format of "Accomplished [X] as measured by [Y], by doing [Z]."
7. Quantify Achievements
8. Use strong action verb
9. One or two page length
  ''')).then((_) {
        return chat;
      });
    });
  });
}

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

class GenerateScreen extends StatelessWidget {
  const GenerateScreen({super.key});

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
      body: SizedBox(
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
                  title: Text('Generate your resume',
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
            const GenerateRequirementForm(),
          ],
        ),
      ),
    );
  }
}

class GenerateRequirementForm extends StatefulWidget {
  const GenerateRequirementForm({super.key});

  @override
  State<GenerateRequirementForm> createState() =>
      _GenerateRequirementFormState();
}

class _GenerateRequirementFormState extends State<GenerateRequirementForm> {
  static const List<String> cvTypeOptions = ['Job', 'Academic'];
  String? _cvType;
  bool? showGenerate = false;
  bool? showResult = false;

  Future<ChatSession>? _chat;

  final TextEditingController _jobAdsController = TextEditingController();
  final TextEditingController _acadmicController = TextEditingController();

  final geminiResultKey = GlobalKey();

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        Scrollable.ensureVisible(geminiResultKey.currentContext!,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Resume for *'),
          subtitle: DropdownButtonFormField(
            value: _cvType,
            hint: const Text(
              'Please Select',
            ),
            isExpanded: true,
            onChanged: (value) {
              setState(() {
                _cvType = value;
                _jobAdsController.text = '';
                _acadmicController.text = '';
              });
            },
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return "Need to choose employment type";
              }
              return null;
            },
            items: cvTypeOptions.map(
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
        if (_cvType == 'Job')
          ListTile(
            title: const Text('Copy Jobs Ads Here *'),
            subtitle: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 10,
              minLines: 5,
              onChanged: (value) {
                if (value.isEmpty && showGenerate == true) {
                  setState(() {
                    showGenerate = false;
                  });
                } else if (value.isNotEmpty && showGenerate == false) {
                  setState(() {
                    showGenerate = true;
                  });
                }
              },
              controller: _jobAdsController,
            ),
          ),
        if (_cvType == 'Academic')
          ListTile(
            title: const Text('Purpose *'),
            subtitle: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 10,
              minLines: 5,
              controller: _acadmicController,
              onChanged: (value) {
                if (value.isEmpty && showGenerate == true) {
                  setState(() {
                    showGenerate = false;
                  });
                } else if (value.isNotEmpty && showGenerate == false) {
                  setState(() {
                    showGenerate = true;
                  });
                }
              },
            ),
          ),
        if (showGenerate == true)
          FilledButton(
            onPressed: () {
              String requirement;
              if (_cvType == 'Job') {
                requirement = _jobAdsController.text;
              } else if (_cvType == 'Academic') {
                requirement = _acadmicController.text;
              } else {
                return;
              }
              setState(() {
                _chat = generateResume(
                    context: context,
                    cvType: _cvType!,
                    requirement: requirement);
                _scrollDown();
              });
            },
            child: const Text('Generate'),
          ),
        if (_chat != null)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            key: geminiResultKey,
            child: FutureBuilder<ChatSession>(
              future: _chat,
              builder:
                  (BuildContext context, AsyncSnapshot<ChatSession> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error.toString()}"),
                  );
                } else if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data?.history == null ||
                      snapshot.hasData == false) {
                    return const Center(
                      child: Text('Empty response'),
                    );
                  }
                  return GeminiChatWidget(
                    chat: snapshot.data!,
                    shortcuts: (textController) {
                      return [
                        GeminiActionChip(
                          name: 'Rate',
                          tooltip: 'Give a rating to the generated result',
                          onPressed: () {
                            textController.text =
                                '''Grade the resume based on the requirements.  Give comments on how to improve.''';
                          },
                        ),
                        GeminiActionChip(
                          name: 'Simulate',
                          tooltip: 'Try to simulate as a reviewer',
                          onPressed: () {
                            textController.text =
                                '''If you are the party looking for the person. Do you think it is a good fit.''';
                          },
                        ),
                      ];
                    },
                  );
                } else {
                  return const LoadingHint(
                      text:
                          'Generating the information. It may takes a while..');
                }
              },
            ),
          )
      ],
    );
  }
}
