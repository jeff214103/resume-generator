class Award {
  String title;
  String issuer;
  String issueDate;
  String description;

  Award(
      {required this.title,
      required this.issuer,
      required this.issueDate,
      required this.description});

  Award.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String,
        issuer = json['issuer'] as String,
        issueDate = json['issueDate'] as String,
        description = json['description'] as String;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'issuer': issuer,
      'issueDate': issueDate,
      'description': description,
    };
  }
}
