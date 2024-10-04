class Skill {
  String skill;

  Skill({required this.skill});

  Skill.fromJson(Map<String, dynamic> json) : skill = json['skill'] as String;

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
    };
  }
}