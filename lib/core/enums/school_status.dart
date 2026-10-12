import 'package:hamrash_admin/core/widgets/app_badge.dart';

// One place that decides the colour of every school status, so the same
// status looks the same on every screen. Show any of these with
// `AppBadge.status(...)`.

enum AttendanceStatus implements BadgeStatus {
  present('Present', AppBadgeTone.success),
  late('Late', AppBadgeTone.warning),
  absent('Absent', AppBadgeTone.error),
  excused('Excused', AppBadgeTone.info),
  notTaken('Not taken', AppBadgeTone.neutral);

  const AttendanceStatus(this.label, this.tone);

  @override
  final String label;
  @override
  final AppBadgeTone tone;
}

enum FeeStatus implements BadgeStatus {
  paid('Paid', AppBadgeTone.success),
  partPaid('Part-paid', AppBadgeTone.warning),
  overdue('Overdue', AppBadgeTone.error),
  scholarship('Scholarship', AppBadgeTone.info),
  notBilled('Not billed', AppBadgeTone.neutral);

  const FeeStatus(this.label, this.tone);

  @override
  final String label;
  @override
  final AppBadgeTone tone;
}

enum ResultStatus implements BadgeStatus {
  published('Published', AppBadgeTone.success),
  awaitingSignOff('Awaiting sign-off', AppBadgeTone.warning),
  missingScores('Missing scores', AppBadgeTone.error),
  draft('Draft', AppBadgeTone.info),
  notStarted('Not started', AppBadgeTone.neutral);

  const ResultStatus(this.label, this.tone);

  @override
  final String label;
  @override
  final AppBadgeTone tone;
}

/// Students and staff.
enum PersonStatus implements BadgeStatus {
  active('Active', AppBadgeTone.success),
  onLeave('On leave', AppBadgeTone.warning),
  suspended('Suspended', AppBadgeTone.error),
  newIntake('New intake', AppBadgeTone.accent),
  graduated('Graduated', AppBadgeTone.neutral);

  const PersonStatus(this.label, this.tone);

  @override
  final String label;
  @override
  final AppBadgeTone tone;
}
