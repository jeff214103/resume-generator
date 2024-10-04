import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'package:personal_cv/providers/data_provider.dart';
import 'package:provider/provider.dart';

Future<List<DataPart>> pickAndConvertFilesToDataParts(BuildContext context) {
  return FilePicker.platform.pickFiles(allowMultiple: true).then((result) {
    if (result == null) return []; // Handle user cancellation gracefully

    final List<PlatformFile> files =
        result.files.where((file) => file.bytes != null).toList();

    return files
        .map((file) {
          final mimeType = lookupMimeType(file.name);
          if (mimeType == null) {
            return null;
          }
          return DataPart(mimeType, file.bytes!);
        })
        .whereType<DataPart>()
        .toList();
  });
}

Future<GenerateContentResponse> geminiResponse(
    {required BuildContext context, required Iterable<Content> prompt}) {
  GenerativeModel model = GenerativeModel(
    model: Provider.of<DataProvider>(context, listen: false).geminiModel,
    apiKey: Provider.of<DataProvider>(context, listen: false).geminiAPIKey,
  );
  return model.generateContent(prompt);
}
