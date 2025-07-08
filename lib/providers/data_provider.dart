import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:personal_cv/model/academic.dart';
import 'package:personal_cv/model/activities.dart';
import 'package:personal_cv/model/award.dart';
import 'package:personal_cv/model/backgroundinfo.dart';
import 'package:personal_cv/model/course.dart';
import 'package:personal_cv/model/language.dart';
import 'package:personal_cv/model/publication.dart';
import 'package:personal_cv/model/skill.dart';
import 'package:personal_cv/model/workexp.dart';
import 'package:personal_cv/util/gemini_helper.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:personal_cv/widget/dialog.dart';
import 'package:personal_cv/widget/gemini.dart';

class DataProvider extends ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool _initialized = false;

  late BackgroundInfo _backgroundInfo;
  BackgroundInfo get backgroundInfo => _backgroundInfo;

  late String _geminiModel;
  String get geminiModel => _geminiModel;

  static const List<String> _availableModels = [
    'gemini-2.0-flash',
    'gemini-2.5-flash',
  ];

  List<String> get availableModels => _availableModels;

  DataProvider() {
    _initialized = false;
  }

  Future<void> init() async {
    if (_initialized == false) {
      const List<String> keys = BackgroundInfo.keys;
      _geminiModel = (await storage.read(key: 'gemini-model')) ?? '';
      if (_geminiModel != '' && availableModels.contains(_geminiModel) == false) {
        _geminiModel = availableModels.first;
      }
      _backgroundInfo =
          await Future.wait(keys.map((key) => storage.read(key: key)))
              .then((values) {
        final json = Map<String, dynamic>.fromIterables(
          keys,
          values.map(
            (e) => (e == null) ? null : jsonDecode(e),
          ),
        );
        return BackgroundInfo.fromJson(json);
      });
    }
  }

  Future<void> cleanAll() async {
    await storage.delete(key: 'gemini-api-key');
    await storage.delete(key: 'gemini-model');

    BackgroundInfo.keys.map((e) => storage.delete(key: e)).toList();

    _backgroundInfo = BackgroundInfo.fromJson({});

    notifyListeners();
  }

  Future<void> initGemini() async {
    if (_geminiModel == '') {
      _geminiModel = availableModels.first;
      print("Set to $_geminiModel");
      return geminiSetting("", _geminiModel);
    }
  }
  Future<void> geminiSetting(String apiKey, String model) async {
    // _geminiAPIKey = apiKey;
    _geminiModel = model;
    // await storage.write(key: 'gemini-api-key', value: _geminiAPIKey);
    await storage.write(key: 'gemini-model', value: _geminiModel);
    notifyListeners();
  }

  Future<void> updateSkills(List<Skill> skills) async {
    backgroundInfo.skills = backgroundInfo.skills
        .followedBy(skills)
        .map((e) => e.skill)
        .toSet()
        .map((e) => Skill(skill: e))
        .toList();
    await storage.write(
      key: 'skills',
      value: jsonEncode(_backgroundInfo.skillsJson()),
    );
  }

  Future<void> updateCourse(List<Course> courses, String location) async {
    Course? findCourse(Course course, List<Course> existingCourses) {
      for (Course existingCourse in existingCourses) {
        if (existingCourse == course) {
          return existingCourse;
        }
      }
      return null;
    }

    List<Course> existingCourses =
        _backgroundInfo.courses.where((e) => e.location == location).toList();
    for (Course course in courses) {
      Course? existingCourse = findCourse(course, existingCourses);
      if (existingCourse != null) {
        course.duration = existingCourse.duration;
        course.startDate = existingCourse.startDate;
        course.description = existingCourse.description;
      }
    }
    _backgroundInfo.courses.removeWhere((e) => e.location == location);
    _backgroundInfo.courses.addAll(courses);

    await storage.write(
      key: 'courses',
      value: jsonEncode(_backgroundInfo.coursesJson()),
    );
  }

  Future<void> addWorkExperience(WorkExperience workExperience) async {
    _backgroundInfo.workExperiences.add(workExperience);
    updateSkills(workExperience.skills);
    notifyListeners();
    await storage.write(
      key: 'workExperiences',
      value: jsonEncode(_backgroundInfo.workExperiencesJson()),
    );
  }

  Future<void> editWorkExperience(
      int index, WorkExperience workExperience) async {
    _backgroundInfo.workExperiences[index] = workExperience;
    updateSkills(workExperience.skills);
    notifyListeners();
    await storage.write(
      key: 'workExperiences',
      value: jsonEncode(_backgroundInfo.workExperiencesJson()),
    );
  }

  Future<void> deleteWorkExperience(int index) async {
    _backgroundInfo.workExperiences.removeAt(index);
    notifyListeners();
    await storage.write(
      key: 'workExperiences',
      value: jsonEncode(_backgroundInfo.workExperiencesJson()),
    );
  }

  Future<void> addAcademic(Academic academic) async {
    _backgroundInfo.academics.add(academic);
    updateSkills(academic.skills);
    updateCourse(academic.courses, academic.school);
    notifyListeners();
    await storage.write(
      key: 'academics',
      value: jsonEncode(_backgroundInfo.academicsJson()),
    );
  }

  Future<void> editAcademic(int index, Academic academic) async {
    _backgroundInfo.academics[index] = academic;
    updateSkills(academic.skills);
    updateCourse(academic.courses, academic.school);
    notifyListeners();
    await storage.write(
      key: 'academics',
      value: jsonEncode(_backgroundInfo.academicsJson()),
    );
  }

  Future<void> deleteAcademice(int index) async {
    Academic academic = _backgroundInfo.academics[index];
    _backgroundInfo.academics.removeAt(index);
    updateCourse([], academic.school);
    notifyListeners();
    await storage.write(
      key: 'academics',
      value: jsonEncode(_backgroundInfo.academicsJson()),
    );
  }

  Future<void> addCourse(Course course) async {
    _backgroundInfo.courses.add(course);
    notifyListeners();
    await storage.write(
      key: 'courses',
      value: jsonEncode(_backgroundInfo.coursesJson()),
    );
  }

  Future<void> editCourse(int index, Course course) async {
    _backgroundInfo.courses[index] = course;
    notifyListeners();
    await storage.write(
      key: 'courses',
      value: jsonEncode(_backgroundInfo.coursesJson()),
    );
  }

  Future<void> deleteCourse(int index) async {
    Course course = _backgroundInfo.courses[index];
    _backgroundInfo.courses.removeAt(index);
    _backgroundInfo.academics
        .where((academic) => academic.school == course.location)
        .forEach(
      (element) {
        element.courses.removeWhere((element) =>
            element.location == course.location &&
            element.title == course.title);
      },
    );
    notifyListeners();
    await storage.write(
      key: 'courses',
      value: jsonEncode(_backgroundInfo.coursesJson()),
    );
  }

  Future<void> addLanguage(Language language) async {
    _backgroundInfo.languages.add(language);
    notifyListeners();
    await storage.write(
      key: 'languages',
      value: jsonEncode(_backgroundInfo.languagesJson()),
    );
  }

  Future<void> editLanguage(int index, Language language) async {
    _backgroundInfo.languages[index] = language;
    notifyListeners();
    await storage.write(
      key: 'languages',
      value: jsonEncode(_backgroundInfo.languagesJson()),
    );
  }

  Future<void> deleteLanguage(int index) async {
    _backgroundInfo.languages.removeAt(index);
    notifyListeners();
    await storage.write(
      key: 'languages',
      value: jsonEncode(_backgroundInfo.languagesJson()),
    );
  }

  Future<void> addActivity(Activity activity) async {
    _backgroundInfo.activities.add(activity);
    notifyListeners();
    await storage.write(
      key: 'activities',
      value: jsonEncode(_backgroundInfo.activitiesJson()),
    );
  }

  Future<void> editActivity(int index, Activity activity) async {
    _backgroundInfo.activities[index] = activity;
    notifyListeners();
    await storage.write(
      key: 'activities',
      value: jsonEncode(_backgroundInfo.activitiesJson()),
    );
  }

  Future<void> deleteActivity(int index) async {
    _backgroundInfo.activities.removeAt(index);
    notifyListeners();
    await storage.write(
      key: 'activities',
      value: jsonEncode(_backgroundInfo.activitiesJson()),
    );
  }

  Future<void> addAward(Award award) async {
    _backgroundInfo.awards.add(award);
    notifyListeners();
    await storage.write(
      key: 'awards',
      value: jsonEncode(_backgroundInfo.awardsJson()),
    );
  }

  Future<void> editAward(int index, Award award) async {
    _backgroundInfo.awards[index] = award;
    notifyListeners();
    await storage.write(
      key: 'awards',
      value: jsonEncode(_backgroundInfo.awardsJson()),
    );
  }

  Future<void> deleteAward(int index) async {
    _backgroundInfo.awards.removeAt(index);
    notifyListeners();
    await storage.write(
      key: 'awards',
      value: jsonEncode(_backgroundInfo.awardsJson()),
    );
  }

  Future<void> addPublication(Publication publication) async {
    _backgroundInfo.publications.add(publication);
    notifyListeners();
    await storage.write(
      key: 'publications',
      value: jsonEncode(_backgroundInfo.publicationsJson()),
    );
  }

  Future<void> editPublication(int index, Publication publication) async {
    _backgroundInfo.publications[index] = publication;
    notifyListeners();
    await storage.write(
      key: 'publications',
      value: jsonEncode(_backgroundInfo.publicationsJson()),
    );
  }

  Future<void> deletePublication(int index) async {
    _backgroundInfo.publications.removeAt(index);
    notifyListeners();
    await storage.write(
      key: 'publications',
      value: jsonEncode(_backgroundInfo.publicationsJson()),
    );
  }

  Future<void> overwriteSkill(List<Skill> skills) async {
    backgroundInfo.skills = skills;
    notifyListeners();
    await storage.write(
      key: 'skills',
      value: jsonEncode(_backgroundInfo.skillsJson()),
    );
  }

  Uint8List backgroundData() {
    final jsonString = jsonEncode(_backgroundInfo);
    final bytes = utf8.encode(jsonString);
    return bytes;
  }

  Future<void> exportData() async {
    if (kIsWeb) {
      final String data = jsonEncode(_backgroundInfo.toJson());

      // Create a Blob object representing the JSON data
      final blob = html.Blob([data], 'application/json');

      // Create a URL for the Blob object
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create an anchor element with the download URL and filename
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "personal.json"); // Add .json extension

      // Simulate a click event to trigger the download
      anchor.click();

      // Revoke the object URL to avoid memory leaks
      html.Url.revokeObjectUrl(url);
    } else {
      throw UnimplementedError("Not implemented in other platform");
    }
  }

  Future<bool> importData() async {
    if (kIsWeb) {
      return FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      ).then((result) {
        if (result != null) {
          final jsonString = String.fromCharCodes(result.files.first.bytes!);

          _backgroundInfo = BackgroundInfo.fromJson(jsonDecode(jsonString));

          Future.wait(
            _backgroundInfo.toJson().entries.map((e) {
              return storage.write(key: e.key, value: jsonEncode(e.value));
            }),
          );

          notifyListeners();
          return true;
        } else {
          return false;
        }
      });
    } else {
      throw UnimplementedError("Not implemented in other platform");
    }
  }

  Future<bool> importAdvance(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return const LoadingDialogBody(
              text: 'Loading and analyzing the information');
        });
    return pickAndConvertFilesToDataParts(context).then((dataParts) {
      final Iterable<Part> newList = List.from([
        TextPart('''
Retrieve the following information of the following aspect, each component an element inside array. 
If the element information not found, fill with empty string.
If the aspect not found, return with empty array.
1. Work Experience JSON. The element as follows.
{
  'title': '<The title of the work experience>',
  'employmentType': '<The employment type of the work experience>',
  'companyName': '<The company name of the work experience>',
  'location': '<The location of the company>',
  'startDate': '<The start date of the work, format: MMMM YYYY>',
  'endDate': '<The end date of the work, format: MMMM YYYY>',
  'description': '<The description of the work>',
  'skills': [] //List of skills JSON
}
2. Academic JSON. The element as follows.
{
  'school': '<The full name of the school>',
  'degree': '<The degree of the education. i.e. Bachelor, Master>',
  'field': '<The field of the education. i.e. Bachelor, Master>',
  'startDate': '<The start date of the education, format: MMMM YYYY>',
  'endDate': '<The end date of the education, format: MMMM YYYY>',
  'description': '<The description of the education>',
  'skills': [], //List of skills JSON
}
3. Skill JSON. The element as follows.
{
  'skill': '<The name of the skill>',
}
4. Language JSON. The element as follows.
{
  'language': '<The name of the lanuage>',
  'proficiency': '<The proficiency of the language. Valid Value: ['Fundamental','Novice','Intermediate','Advanced','Expert'>',
}
5. Activity JSON. The element as follows.
{
  'title': '<The title of the activity>',
  'location': '<The location of the activity>',
  'startDate': '<The start date of the activity, format: MMMM YYYY>',
  'duration': '<The duration of the activity, i.e. 8 months, 1 days, 3 years>',
  'description': '<The description of the activity>',
}
6. Award JSON. The element as follows.
{
  'title': '<The title of the award>',
  'issuer':  '<The issuer of the award>',
  'issueDate': '<The issue date of the award>',
  'description': '<The description of the award>',
}
7. Course JSON. The element as follows.
{
  'title': '<The title of the course>',
  'location': '<The location of the course>',
  'startDate': '<The start date of the course, format: MMMM YYYY>',
  'duration': '<The duration of the course, i.e. 8 months, 1 days, 3 years>',
  'description': '<The description of the course>',
}
8. Publication JSON. The element as follows.
{
  'title': '<The title of the publication>',
  'publication': '<The publication authority of the publication>',
  'date': '<The date of the publication, format: MMMM YYYY>',
  'description': '<The description of the publication>',
}

Return the result using this JSON schema:
{
  "workExperiences": [], //List of Work Experience JSON
  "academics": [], //List of Academic JSON
  "skills": [], //List of Skill JSON
  "languages": [], //List of Language JSON
  "activities": [], //List of Activity JSON
  "awards": [], //List of Award JSON
  "courses": [], //List of Course JSON
  "publications": [] //List of Publication JSON
}
''')
      ])
        ..addAll(dataParts);
      if (dataParts.isEmpty) {
        throw Exception('No files selected');
      }

      FirebaseAnalytics.instance.logEvent(name : 'import', parameters: {
        'files': dataParts.length
      });

      return geminiResponse(
              context: context,
              prompt: [Content.multi(newList)],
              responseMimeType: 'application/json')
          .then((response) {
        if (response.text == null) {
          throw Exception('Empty respoonse');
        }
        Navigator.of(context).pop();
        try {
          _backgroundInfo = BackgroundInfo.fromJson(jsonDecode(response.text!));

          Future.wait(
            _backgroundInfo.toJson().entries.map((e) {
              return storage.write(key: e.key, value: jsonEncode(e.value));
            }),
          );

          notifyListeners();

          return true;
        } catch (e) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return GeminiRawResponse(
                response: response.text ?? 'null',
              );
            },
          );
          return false;
        }
      });
    }).catchError((error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting files: $error')),
      );
      return false;
    });
  }
}
