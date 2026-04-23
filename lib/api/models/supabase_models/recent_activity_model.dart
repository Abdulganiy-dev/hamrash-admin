/// App model representing a recent activity entry in the school system.
class RecentActivityModel {
  const RecentActivityModel({
    required this.title,
    required this.date,
  });

  final String title;
  final DateTime date;

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      title: json['title'] as String,
      date: _parseDateTime(json['date']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String(),
      };

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
