import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/screen/welcome.dart';
import 'package:personal_cv/widget/gemini.dart';
import 'package:personal_cv/util/gemini_helper.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

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
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _loadingMessage = '';

  Future<ChatSession>? _chat;

  final TextEditingController _jobAdsController = TextEditingController();
  final TextEditingController _acadmicController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final geminiResultKey = GlobalKey();

  @override
  void dispose() {
    _jobAdsController.dispose();
    _acadmicController.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        Scrollable.ensureVisible(geminiResultKey.currentContext!,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut));
  }

  void _resetForm() {
    setState(() {
      _cvType = null;
      _jobAdsController.clear();
      _acadmicController.clear();
      _hasError = false;
      _errorMessage = '';
      _isLoading = false;
      _loadingMessage = '';
    });
  }

  Future<void> _generateResume() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _loadingMessage = '';
    });

    try {
      String requirement;
      if (_cvType == 'Job') {
        requirement = _jobAdsController.text.trim();
      } else if (_cvType == 'Academic') {
        requirement = _acadmicController.text.trim();
      } else {
        throw Exception('Invalid resume type');
      }

      if (requirement.isEmpty) {
        throw Exception('Please provide resume requirements');
      }

      final chat = await generateResume(
        context: context,
        cvType: _cvType!,
        requirement: requirement,
      );

      setState(() {
        _chat = Future.value(chat);
        _isLoading = false;
      });

      _scrollDown();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<ChatSession> generateResume(
      {required BuildContext context,
      required String cvType,
      required String requirement}) {
    // Local loading message tracking
    void updateLoadingMessage(String message) {
      setState(() {
        _loadingMessage = message;
      });
    }

    FirebaseAnalytics.instance.logEvent(name: 'generate_resume', parameters: {
      'cvType': cvType,
      'requirement': requirement,
    });

    updateLoadingMessage('Initializing resume generation...');

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

    updateLoadingMessage('Connecting to AI model...');
    GenerativeModel model = getFirebaseAI().generativeModel(
        model: Provider.of<DataProvider>(context, listen: false).geminiModel);
    ChatSession chat = model.startChat();

    updateLoadingMessage('Loading background information...');
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
      updateLoadingMessage('Processing resume requirements...');
      return chat.sendMessage(Content.text(prompt)).then((_) {
        updateLoadingMessage('Generating tailored resume content...');
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
10. Order each items in the category from most recent to least recent
  ''')).then((_) {
          updateLoadingMessage('Resume generation complete');
          return chat;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _cvType,
              decoration: InputDecoration(
                labelText: 'Resume Type *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              hint: const Text('Select Resume Type'),
              isExpanded: true,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _cvType = value;
                        _jobAdsController.clear();
                        _acadmicController.clear();
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a resume type';
                }
                return null;
              },
              items: cvTypeOptions.map((String val) {
                return DropdownMenuItem(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_cvType == 'Job')
              TextFormField(
                controller: _jobAdsController,
                decoration: InputDecoration(
                  labelText: 'Job Description *',
                  hintText: 'Paste job advertisement details',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide job description';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
            if (_cvType == 'Academic')
              TextFormField(
                controller: _acadmicController,
                decoration: InputDecoration(
                  labelText: 'Academic Purpose *',
                  hintText: 'Describe academic requirements',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide academic purpose';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
            const SizedBox(height: 16),
            if (_hasError)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _generateResume,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              LinearProgressIndicator(
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            if (_chat != null)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                key: geminiResultKey,
                child: FutureBuilder<ChatSession>(
                  future: _chat,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error Generating Resume',
                              style: textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _resetForm,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasData) {
                      return GeminiChatWidget(
                        chat: snapshot.data!,
                        shortcuts: (textController) {
                          return [
                            GeminiActionChip(
                              filled: true,
                              name: 'Cover Letter',
                              tooltip: 'Write cover letter',
                              onPressed: () {
                                textController.text =
                                    '''Write a cover letter based on the requirement and background base on the following instruction.
1. Use professional tone
2. Limit to 500 words
3. Highlight the key points
4. Use bullet points''';
                              },
                            ),
                            GeminiActionChip(
                              name: 'Rate',
                              tooltip: 'Give a rating to the generated result',
                              onPressed: () {
                                textController.text =
                                    '''Grade the document based on the requirements.  Give comments on how to improve.''';
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
                      return const Center(
                        child: Text('No resume generated'),
                      );
                    }
                  },
                ),
              ),
            if (_isLoading)
              Text(
                _loadingMessage,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
