/// The parts of a school that are run from the More tab.
enum SchoolArea {
  academicCalendar('Academic calendar'),
  classes('Classes and arms'),
  subjects('Subjects'),
  grading('Grading'),
  team('Team and invites'),
  schoolDetails('School details');

  const SchoolArea(this.title);

  final String title;
}

/// What someone can do in a [SchoolArea]. Worked out from their roles by
/// [MemberSchool.accessTo], to match the database's row-level rules.
enum AreaAccess {
  /// They can't see it at all, so the area isn't shown.
  none,

  /// They can read it but not change it.
  view,

  /// They can add, edit and (where the database allows) remove.
  manage;

  bool get isVisible => this != none;
}
