import 'package:hamrash_admin/api/models/grading/section_grading.dart';
import 'package:hamrash_admin/core/widgets/app_badge.dart';

/// The status word used on the sections list and the two task rows.
AppBadge gradingStatusBadge(GradingStatus status) => AppBadge(
  status.label,
  tone: switch (status) {
    GradingStatus.setUp => AppBadgeTone.success,
    GradingStatus.partlySetUp => AppBadgeTone.warning,
    GradingStatus.notSetUp => AppBadgeTone.neutral,
  },
);
