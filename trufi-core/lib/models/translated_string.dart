class TranslatedString {
  final String? text;
  final String? language;

  const TranslatedString({this.text, this.language});

  static const String _text = 'text';
  static const String _language = 'language';

  factory TranslatedString.fromJson(Map<String, dynamic> json) =>
      TranslatedString(text: json[_text], language: json[_language]);

  Map<String, dynamic> toJson() => {_text: text, _language: language};
}
