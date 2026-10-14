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

/// Admin-app members at a school: who has joined and who is still invited.
class TeamCount {
  const TeamCount({required this.active, required this.invited});

  final int active;
  final int invited;

  /// "4 people · 1 invite".
  String get label {
    final people = active == 1 ? '1 person' : '$active people';
    if (invited == 0) return people;
    return '$people · ${invited == 1 ? '1 invite' : '$invited invites'}';
  }
}
