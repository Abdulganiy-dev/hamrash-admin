import 'package:hamrash_admin/api/models/grading/grading_numbers.dart';

/// One part of a subject's score, like CA 1 out of 20. A subject's total is
/// the sum of its columns' scores out of the sum of their [maxScore]s.
///
/// A column belongs to one set: a section's own columns when [sectionId] is
/// set, otherwise the school-level set. A section with any own columns uses
/// them instead of the school's.
class ScoreColumn {
  const ScoreColumn({
    required this.id,
    required this.name,
    required this.maxScore,
    required this.sortOrder,
    this.sectionId,
  });

  final String id;
  final String name;

  /// The most the column can earn, above 0 with up to 2 decimals.
  final double maxScore;

  /// Report-card order.
  final int sortOrder;

  /// The section whose own set this column belongs to, or null for the
  /// school-level set.
  final String? sectionId;

  static const columns = 'id,section_id,name,max_score,sort_order';

  factory ScoreColumn.fromJson(Map<String, dynamic> json) => ScoreColumn(
    id: json['id'] as String,
    sectionId: json['section_id'] as String?,
    name: json['name'] as String,
    maxScore: (json['max_score'] as num).toDouble(),
    sortOrder: json['sort_order'] as int,
  );

  ScoreColumn copyWith({
    String? id,
    String? name,
    double? maxScore,
    int? sortOrder,
    String? sectionId,
  }) => ScoreColumn(
    id: id ?? this.id,
    sectionId: sectionId ?? this.sectionId,
    name: name ?? this.name,
    maxScore: maxScore ?? this.maxScore,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  /// "Out of 20".
  String get outOf => 'Out of ${GradingNumbers.format(maxScore)}';
}
