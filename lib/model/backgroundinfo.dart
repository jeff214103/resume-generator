import 'package:personal_cv/model/academic.dart';
import 'package:personal_cv/model/activities.dart';
import 'package:personal_cv/model/award.dart';
import 'package:personal_cv/model/course.dart';
import 'package:personal_cv/model/language.dart';
import 'package:personal_cv/model/publication.dart';
import 'package:personal_cv/model/skill.dart';
import 'package:personal_cv/model/workexp.dart';

class BackgroundInfo {
  static const List<String> keys = [
    'workExperiences',
    'academics',
    'skills',
    'languages',
    'activities',
    'awards',
    'courses',
    'publications'
  ];
  List<WorkExperience> workExperiences;
  List<Academic> academics;
  List<Skill> skills;
  List<Language> languages;
  List<Activity> activities;
  List<Award> awards;
  List<Course> courses;
  List<Publication> publications;

  BackgroundInfo(
      {required this.workExperiences,
      required this.academics,
      required this.skills,
      required this.languages,
      required this.activities,
      required this.awards,
      required this.courses,
      required this.publications});

  BackgroundInfo.fromJson(Map<String, dynamic> json)
      : workExperiences = (json['workExperiences'] != null)
            ? List<WorkExperience>.from(json['workExperiences']
                .map((data) => WorkExperience.fromJson(data)))
            : [],
        academics = (json['academics'] != null)
            ? List<Academic>.from(
                json['academics'].map((data) => Academic.fromJson(data)))
            : [],
        skills = (json['skills'] != null)
            ? List<Skill>.from(
                json['skills'].map((data) => Skill.fromJson(data)))
            : [],
        languages = (json['languages'] != null)
            ? List<Language>.from(
                json['languages'].map((data) => Language.fromJson(data)))
            : [],
        activities = (json['activities'] != null)
            ? List<Activity>.from(
                json['activities'].map((data) => Activity.fromJson(data)))
            : [],
        awards = (json['awards'] != null)
            ? List<Award>.from(
                json['awards'].map((data) => Award.fromJson(data)))
            : [],
        courses = (json['courses'] != null)
            ? List<Course>.from(
                json['courses'].map((data) => Course.fromJson(data)))
            : [],
        publications = (json['publications'] != null)
            ? List<Publication>.from(
                json['publications'].map((data) => Publication.fromJson(data)))
            : [];

  List<Map<String, dynamic>> workExperiencesJson() {
    return workExperiences
        .map(
          (e) => e.toJson(),
        )
        .toList();
  }

  List<Map<String, dynamic>> academicsJson() {
    return academics
        .map(
          (e) => e.toJson(),
        )
        .toList();
  }

  List<Map<String, dynamic>> skillsJson() {
    return skills
        .map(
          (e) => e.toJson(),
        )
        .toList();
  }

  List<Map<String, dynamic>> languagesJson() {
    return languages
        .map(
          (e) => e.toJson(),
        )
        .toList();
  }

  List<Map<String, dynamic>> activitiesJson() {
    return activities
        .map(
          (e) => e.toJson(),
        )
        .toList();
  }

  List<Map<String, dynamic>> awardsJson() {
    return awards
        .map(
          (e) => e.toJson(),
        )
        .toList();
  }

  List<Map<String, dynamic>> coursesJson() {
    return courses
        .map(
          (e) => e.toJson(),
        )
        .toList();
  }

  List<Map<String, dynamic>> publicationsJson() {
    return publications
        .map(
          (e) => e.toJson(),
        )
        .toList();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    List data;
    data = workExperiencesJson();
    if (data.isNotEmpty) {
      result['workExperiences'] = data;
    }
    data = academicsJson();
    if (data.isNotEmpty) {
      result['academics'] = data;
    }
    data = skillsJson();
    if (data.isNotEmpty) {
      result['skills'] = data;
    }
    data = languagesJson();
    if (data.isNotEmpty) {
      result['languages'] = data;
    }
    data = activitiesJson();
    if (data.isNotEmpty) {
      result['activities'] = data;
    }
    data = awardsJson();
    if (data.isNotEmpty) {
      result['awards'] = data;
    }
    data = coursesJson();
    if (data.isNotEmpty) {
      result['courses'] = data;
    }
    data = publicationsJson();
    if (data.isNotEmpty) {
      result['publications'] = data;
    }
    return result;
  }
}
