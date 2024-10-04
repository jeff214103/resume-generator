class Language {
  String language;
  String proficiency;

  Language({required this.language, required this.proficiency});

  Language.fromJson(Map<String, dynamic> json)
      : language = json['language'] as String,
        proficiency = json['proficiency'] as String;

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'proficiency': proficiency,
    };
  }
}
