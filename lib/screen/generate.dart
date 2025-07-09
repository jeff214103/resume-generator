import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:personal_cv/screen/welcome.dart';
import 'package:personal_cv/widget/gemini.dart';
import 'package:personal_cv/util/gemini_helper.dart';
import 'package:personal_cv/widget/pdf.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
      prompt =
          '''You are a professional resume writer. The resume target is to apply job.
    The requirements of the job as the follows.
    '$requirement'
    Ensure your resume is suitable and target for the job.
    Wait for the user background information in the next prompt before any action.
  ''';
    } else if (cvType == 'Academic') {
      prompt =
          '''You are a professional resume writer. The resume target is for academic requirements.
    The requirements of the academic as the follows.
    '$requirement'
    Ensure your resume is suitable and target for the academic.
    Wait for the user background information in the next prompt before any action.
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
Understand the background by looking into the json.
'${jsonEncode(Provider.of<DataProvider>(context, listen: false).backgroundInfo)}'
Only use the above background information as the resume details.
Wait for my instruction in the next prompt for the output requirements.
            ''',
      ),
    )
        .then((_) {
      updateLoadingMessage('Processing resume requirements...');
      return chat.sendMessage(Content.text(prompt)).then((_) {
        updateLoadingMessage('Generating tailored resume content...');
        return chat.sendMessage(Content.text('''
Please do the pre-checking before writing the resume.
1. If the user has not provided any background information, no matter which prompt following it is, always return "Please provide your background information first before generating a resume."
2. If the user provide with invalid requirements, no matter which prompt following it is, always return "Please provide a valid requirement before generating a resume." 
3. If the user do not fullfill both two conditions, no matter which prompt following it is, always return "Please provide your background information and requirement before generating a resume."
4. If everything is ready, finish the resume based on the requirement

Resume writing instruction
1. Prioritize and highlight the background information fulfill the requirement
2. Use the requirement keyword for the relvant background information elaboration
3. Tailoring for the Role
4. Every point should base on given background information, do not make up
5. Do not provide filling blanks or information, the result should be ready to use
6. Highlighting Preferred Qualifications
7. For work experience, write point in the format of "Accomplished [X] as measured by [Y], by doing [Z]."
8. Quantify Achievements
9. Use strong action verb
10. Less than two page length
11. Order each items in the category from most recent to least recent
12. Do not include information that is outdated or not relevant, unless it is not enough information to be written
13. Return only the resume content without any introduction, explanation, or conclusion
14. Return in markdown format, wrap the resume content in ```resume <resume content>```
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
                      return GenerationResult(chat: snapshot.data!);
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

class GenerationResult extends StatefulWidget {
  const GenerationResult({
    super.key,
    required this.chat,
  });

  final ChatSession chat;

  @override
  State<GenerationResult> createState() => _GenerationResultState();
}

class _GenerationResultState extends State<GenerationResult> {
  bool _usePdfWidget = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('View:'),
            Switch(
              value: _usePdfWidget,
              onChanged: (val) {
                setState(() {
                  _usePdfWidget = val;
                });
              },
            ),
            Text(_usePdfWidget ? 'PDF' : 'Chat'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Follow Up'),
              onPressed: _isLoading ? null : _handleFollowup,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.description),
              label: const Text('Cover Letter'),
              onPressed: _isLoading ? null : _handleCoverLetter,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.star),
              label: const Text('Rate'),
              onPressed: _isLoading ? null : _handleRate,
            ),
          ],
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),
        Flexible(
          child: IndexedStack(
            index: _usePdfWidget ? 0 : 1,
            children: [
              _buildPdfList(),
              GeminiChatWidget(
                loading: _isLoading,
                chat: widget.chat,
              ),
            ]
                .map(
                  (e) => Align(
                    alignment: Alignment.topCenter,
                    child: e,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  bool _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFollowup() async {
    // Extract available document types from chat history (same as _buildPdfList logic)
    final Map<String, Map<String, dynamic>> latestDocs = {};
    final RegExp markdownRegex =
        RegExp(r'```(\w[\w ]*)\s*(.*?)\s*```', dotAll: true);
    final history = widget.chat.history.toList();
    for (int i = history.length - 1; i >= 0; i--) {
      final msg = history[i];
      if (msg.role == 'user') continue;
      final text = msg.parts.whereType<TextPart>().map((e) => e.text).join('');
      final match = markdownRegex.firstMatch(text);
      if (match != null && match.groupCount >= 2) {
        final docType = (match.group(1)?.trim() ?? 'Document');
        if (!latestDocs.containsKey(docType)) {
          latestDocs[docType] = {};
        }
      }
    }
    final docTypes = latestDocs.keys.toList();

    String? selectedDocType = docTypes.isNotEmpty ? docTypes.first : null;
    String followupText = '';
    final controller = TextEditingController();

    final feedback = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Follow Up'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedDocType,
                      items: docTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedDocType = val;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Any follow up to the current document?',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 5,
                      autofocus: true,
                      onChanged: (val) {
                        setState(() {
                          followupText = val.trim();
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      (selectedDocType != null && followupText.isNotEmpty)
                          ? () => Navigator.of(context).pop({
                                'docType': selectedDocType!,
                                'text': followupText,
                              })
                          : null,
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
    if (feedback == null ||
        feedback['text']!.isEmpty ||
        feedback['docType'] == null) return;
    setState(() => _isLoading = true);
    try {
      await widget.chat.sendMessage(Content.text(
          'Update the previous ${feedback['docType']} document based on the following follow up. Return the updated document in markdown format only, wrapped in ```resume <updated resume>``` or ```cover letter <updated cover letter>``` as appropriate. Follow up: ${feedback['text']}'));
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCoverLetter() async {
    setState(() => _isLoading = true);
    try {
      await widget.chat.sendMessage(Content.text(
        '''Write a cover letter based on the requirement and background base on the following instruction.
1. Use professional tone
2. Limit to 500 words
3. Highlight the key points
4. Use bullet points
Return only the cover letter in markdown format, wrapped in ```cover letter <cover letter content>```.''',
      ));
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRate() async {
    setState(() => _isLoading = true);
    String? ratingResult;
    try {
      await widget.chat.sendMessage(Content.text(
        'Imagine you are the reviewer. Grade the document based on the requirements. Give comments on how to improve. Return only the rating and comments, no markdown.',
      ));
      // After sending, the latest message is at the end of widget.chat.history
      ratingResult = widget.chat.history.last.parts
          .whereType<TextPart>()
          .map((e) => e.text)
          .join('');
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
    if (ratingResult != null && ratingResult.isNotEmpty) {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rating Result'),
          content: SingleChildScrollView(
            child: SelectionArea(
              child: MarkdownBody(
                data: ratingResult!,
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.primary),
                  code: TextStyle(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurface),
                  codeblockDecoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4)),
                  // Add more styles as needed
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  String toTitleCase(String str) {
    return str
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildPdfList() {
    final Map<String, Map<String, dynamic>> latestDocs = {};
    final Map<String, int> versionCounts = {};
    final RegExp markdownRegex =
        RegExp(r'```(\w[\w ]*)\s*(.*?)\s*```', dotAll: true);
    final history = widget.chat.history.toList();

    // Iterate in reverse to get the latest for each doc type
    for (int i = history.length - 1; i >= 0; i--) {
      final msg = history[i];
      if (msg.role == 'user') continue;
      final text = msg.parts.whereType<TextPart>().map((e) => e.text).join('');
      final match = markdownRegex.firstMatch(text);
      if (match != null && match.groupCount >= 2) {
        final docType = (match.group(1)?.trim() ?? 'Document');
        final content = match.group(2) ?? text;
        if (!latestDocs.containsKey(docType)) {
          // Count total versions for this docType
          versionCounts[docType] = history.where((m) {
            if (m.role == 'user') return false;
            final t = m.parts.whereType<TextPart>().map((e) => e.text).join('');
            final mt = markdownRegex.firstMatch(t);
            return mt != null && (mt.group(1)?.trim() ?? '') == docType;
          }).length;
          latestDocs[docType] = {
            'content': content,
            'version': versionCounts[docType]!,
          };
        }
      }
    }

    if (latestDocs.isEmpty) {
      return Center(
          child: Text(widget.chat.history.last.parts
              .whereType<TextPart>()
              .map((e) => e.text)
              .join('')));
    }

    final pdfPreviews = latestDocs.entries.map((entry) {
      final docType = entry.key;
      final content = entry.value['content'] as String;
      final version = entry.value['version'] as int;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: PdfWidget(
          content: content,
          title: '${toTitleCase(docType)} v$version',
          fileName:
              '${docType.replaceAll(' ', '_').toLowerCase()}_v$version.pdf',
          isPaid: false,
        ),
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // Wide screen: Row
          return Row(
            children: pdfPreviews
                .map(
                  (e) => Expanded(
                    child: e,
                  ),
                )
                .toList(),
          );
        } else {
          // Narrow screen: Column
          return ListView(
            shrinkWrap: true,
            children: pdfPreviews,
          );
        }
      },
    );
  }
}
