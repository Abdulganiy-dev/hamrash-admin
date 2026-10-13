/// The first-run checklist on Home, in the order a school should do them.
enum SetupStep {
  schoolDetails('School details', 'Name, logo and contact details'),
  academicCalendar('Academic calendar', 'Add the session and the current term'),
  classes('Classes and arms', 'Sections, classes and their arms'),
  subjects('Subjects', 'What each class takes'),
  grading('Grading', 'Grade scale and CA weights'),
  team('Invite your team', 'Admins, principal, VP and bursar'),
  people('Add staff and students', 'One at a time for now');

  const SetupStep(this.title, this.hint);

  final String title;
  final String hint;
}

/// Which [SetupStep]s a school has done, worked out from its own records.
class SetupProgress {
  const SetupProgress(this.done);

  final Set<SetupStep> done;

  int get doneCount => done.length;
  int get total => SetupStep.values.length;
  bool get isComplete => doneCount == total;

  bool isDone(SetupStep step) => done.contains(step);

  /// The first step not done yet, or null when everything is done.
  SetupStep? get current {
    for (final step in SetupStep.values) {
      if (!done.contains(step)) return step;
    }
    return null;
  }

  /// Steps still to do after [current].
  int get remainingAfterCurrent => current == null ? 0 : total - doneCount - 1;
}
