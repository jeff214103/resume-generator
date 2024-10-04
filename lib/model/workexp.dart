import 'package:personal_cv/model/skill.dart';

class WorkExperience {
  String title;
  String employmentType;
  String companyName;
  String location;
  String startDate;
  String endDate;
  String description;
  List<Skill> skills;

  WorkExperience({
    required this.title,
    required this.employmentType,
    required this.companyName,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.description,
    this.skills = const [],
  });

  WorkExperience.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String,
        employmentType = json['employmentType'] as String,
        companyName = json['companyName'] as String,
        location = json['location'] as String,
        startDate = json['startDate'] as String,
        endDate = json['endDate'] as String,
        description = json['description'] as String,
        skills = (json['skills'] != null)
            ? List<Skill>.from(
                json['skills'].map((data) => Skill.fromJson(data)))
            : [];

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'employmentType': employmentType,
      'companyName': companyName,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
      'skills': skills
          .map(
            (e) => e.toJson(),
          )
          .toList()
    };
  }
}
