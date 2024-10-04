class Activity {
  String title;
  String location;
  String startDate;
  String duration;
  String description;

  Activity(
      {required this.title,
      required this.location,
      required this.startDate,
      required this.duration,
      required this.description});

  Activity.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String,
        location = json['location'] as String,
        startDate = json['startDate'] as String,
        duration = json['duration'] as String,
        description = json['description'] as String;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'startDate': startDate,
      'duration': duration,
      'description': description,
    };
  }
}
