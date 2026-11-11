/// The term the school is in now, e.g. "2026/27 · First term".
class CurrentTerm {
  const CurrentTerm({required this.sessionName, required this.termName});

  factory CurrentTerm.fromJson(Map<String, dynamic> json) => CurrentTerm(
    termName: json['name'] as String,
    sessionName: (json['session'] as Map<String, dynamic>)['name'] as String,
  );

  final String sessionName;
  final String termName;

  String get label => '$sessionName · $termName';
}
