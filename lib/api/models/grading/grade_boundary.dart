/// Where a grade starts: A from 70%, F from 0%. A score gets the grade with
/// the highest [minPercent] it reaches.
class GradeBoundary {
  const GradeBoundary({
    required this.id,
    required this.grade,
    required this.minPercent,
    required this.remark,
    required this.isPass,
  });

  final String id;
  final String grade;

  /// 0 up to (not including) 100, with up to 2 decimals.
  final double minPercent;

  /// "Excellent", "Very Good"… printed on report cards. Optional.
  final String? remark;

  /// Whether this grade counts as a pass on report cards.
  final bool isPass;

  static const columns = 'id,grade,min_percent,remark,is_pass';

  factory GradeBoundary.fromJson(Map<String, dynamic> json) => GradeBoundary(
    id: json['id'] as String,
    grade: json['grade'] as String,
    minPercent: (json['min_percent'] as num).toDouble(),
    remark: json['remark'] as String?,
    isPass: json['is_pass'] as bool,
  );
}
