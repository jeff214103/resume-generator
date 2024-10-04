import 'package:personal_cv/model/course.dart';
import 'package:personal_cv/model/skill.dart';

class Academic {
  String school;
  String degree;
  String field;
  String startDate;
  String endDate;
  String description;
  List<Skill> skills;
  List<Course> courses;

  Academic({
    required this.school,
    required this.degree,
    required this.field,
    required this.startDate,
    required this.endDate,
    required this.description,
    this.skills = const [],
    this.courses = const [],
  });

  Academic.fromJson(Map<String, dynamic> json)
      : school = json['school'] as String,
        degree = json['degree'] as String,
        field = json['field'] as String,
        startDate = json['startDate'] as String,
        endDate = json['endDate'] as String,
        description = json['description'] as String,
        skills = (json['skills'] != null)
            ? List<Skill>.from(
                json['skills'].map((data) => Skill.fromJson(data)))
            : [],
        courses = (json['courses'] != null)
            ? List<Course>.from(
                json['courses'].map((data) => Course.fromJson(data)))
            : [];

  Map<String, dynamic> toJson() {
    return {
      'school': school,
      'degree': degree,
      'field': field,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
      'skills': skills
          .map(
            (e) => e.toJson(),
          )
          .toList(),
      'courses': courses
          .map(
            (e) => e.toJson(),
          )
          .toList()
    };
  }
}
