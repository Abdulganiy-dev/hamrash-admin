/// One grade band in a scale: A from 70% to 100%, F from 0% to 39%.
///
/// Ranges are whole numbers and, within one set, tile 0 to 100 exactly:
/// the lowest starts at 0, each starts at the one below's max plus one, and
/// the top ends at 100. A section with its own rows uses them instead of the
/// school-level set.
class GradeBoundary {
  const GradeBoundary({
    required this.id,
    required this.grade,
    required this.minPercent,
    required this.maxPercent,
    required this.remark,
    required this.isPass,
    this.sectionId,
  });

  final String id;
  final String grade;

  /// The section whose own scale this grade belongs to, or null for the
  /// school-level set.
  final String? sectionId;

  /// 0 to 100, whole numbers.
  final int minPercent;

  /// 0 to 100, whole numbers, never below [minPercent].
  final int maxPercent;

  /// "Excellent", "Very Good"… printed on report cards. Optional.
  final String? remark;

  /// Whether this grade counts as a pass on report cards.
  final bool isPass;

  static const columns =
      'id,section_id,grade,min_percent,max_percent,remark,is_pass';

  factory GradeBoundary.fromJson(Map<String, dynamic> json) => GradeBoundary(
    id: json['id'] as String,
    sectionId: json['section_id'] as String?,
    grade: json['grade'] as String,
    minPercent: (json['min_percent'] as num).toInt(),
    maxPercent: (json['max_percent'] as num).toInt(),
    remark: json['remark'] as String?,
    isPass: json['is_pass'] as bool,
  );

  GradeBoundary copyWith({
    String? id,
    String? grade,
    int? minPercent,
    int? maxPercent,
    String? remark,
    bool clearRemark = false,
    bool? isPass,
    String? sectionId,
  }) => GradeBoundary(
    id: id ?? this.id,
    sectionId: sectionId ?? this.sectionId,
    grade: grade ?? this.grade,
    minPercent: minPercent ?? this.minPercent,
    maxPercent: maxPercent ?? this.maxPercent,
    remark: clearRemark ? null : (remark ?? this.remark),
    isPass: isPass ?? this.isPass,
  );

  /// "70 to 100".
  String get range => '$minPercent to $maxPercent';

  /// "Pass", or "Fail" for a grade that doesn't count as one.
  String get flag => isPass ? 'Pass' : 'Fail';
}
