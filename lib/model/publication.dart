class Publication {
  String title;
  String publication;
  String date;
  String description;

  Publication(
      {required this.title,
      required this.publication,
      required this.date,
      required this.description});

  Publication.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String,
        publication = json['publication'] as String,
        date = json['date'] as String,
        description = json['description'] as String;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'publication': publication,
      'date': date,
      'description': description,
    };
  }
}
