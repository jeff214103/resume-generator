class Course {
  String title;
  String? location;
  String? startDate;
  String? duration;
  String? description;

  Course(
      {required this.title,
      this.location,
      this.startDate,
      this.duration,
      this.description});

  Course.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String,
        location = json['location'] as String?,
        startDate = json['startDate'] as String?,
        duration = json['duration'] as String?,
        description = json['description'] as String?;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'startDate': startDate,
      'duration': duration,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course && title == other.title && location == other.location;

  @override
  int get hashCode => Object.hash(title, location);
}
