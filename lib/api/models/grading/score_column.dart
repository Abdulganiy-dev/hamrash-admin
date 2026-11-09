import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';

/// One part of a subject's score, like CA 1 out of 20. A subject's total is
/// the sum of its columns' scores out of the sum of their [maxScore]s.
class ScoreColumn {
  const ScoreColumn({
    required this.id,
    required this.name,
    required this.maxScore,
    required this.sortOrder,
  });

  final String id;
  final String name;

  /// The most the column can earn, above 0 with up to 2 decimals.
  final double maxScore;

  /// Report-card order.
  final int sortOrder;

  static const columns = 'id,name,max_score,sort_order';

  factory ScoreColumn.fromJson(Map<String, dynamic> json) => ScoreColumn(
    id: json['id'] as String,
    name: json['name'] as String,
    maxScore: (json['max_score'] as num).toDouble(),
    sortOrder: json['sort_order'] as int,
  );

  /// "Out of 20".
  String get outOf => 'Out of ${GradingNumbers.format(maxScore)}';
}
