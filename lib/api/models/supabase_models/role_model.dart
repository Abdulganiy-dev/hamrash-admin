/// App model for `public.roles`.
class RoleModel {
  const RoleModel({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime? createdAt;

  /// Human-readable name for UI (e.g. `super_admin` → "Super Admin").
  String get displayLabel {
    final parts = name.split('_').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return name;
    return parts
        .map((word) {
          final lower = word.toLowerCase();
          if (lower.isEmpty) return word;
          return '${lower[0].toUpperCase()}'
              '${lower.length > 1 ? lower.substring(1) : ''}';
        })
        .join(' ');
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: _asString(json['id']),
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'created_at': createdAt?.toIso8601String(),
      };

  static String _asString(dynamic v) => v is String ? v : v.toString();

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
