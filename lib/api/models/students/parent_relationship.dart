/// How a parent is related to a student (`public.parent_relationship`).
enum ParentRelationship {
  mother('mother', 'Mother'),
  father('father', 'Father'),
  guardian('guardian', 'Guardian'),
  other('other', 'Other');

  const ParentRelationship(this.value, this.label);

  /// What the database stores.
  final String value;

  /// What the app shows.
  final String label;

  /// A sensible first guess from a title, or null when the title says
  /// nothing about it. The person can always change it.
  static ParentRelationship? guessFromTitle(String? title) =>
      switch (title?.trim().toLowerCase()) {
        'mr' || 'alhaji' => ParentRelationship.father,
        'mrs' || 'alhaja' => ParentRelationship.mother,
        _ => null,
      };
}

/// The titles offered for a new parent.
abstract final class ParentTitles {
  static const values = [
    'Mr',
    'Mrs',
    'Miss',
    'Ms',
    'Dr',
    'Prof',
    'Chief',
    'Alhaji',
    'Alhaja',
  ];
}
