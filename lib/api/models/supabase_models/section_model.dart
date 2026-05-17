/// App model for `public.sections`.
class SectionModel {
  const SectionModel({
    this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: _asString(json['id']),
      name: json['name'] as String,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toInsertJson() => {'name': name.trim()};

  Map<String, dynamic> toUpdateJson() => {
        'name': name.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  SectionModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _asString(dynamic v) => v is String ? v : v.toString();

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
