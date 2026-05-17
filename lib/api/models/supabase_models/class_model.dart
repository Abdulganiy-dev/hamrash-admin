/// App model for `public.classes`.
class ClassModel {
  const ClassModel({
    this.id,
    required this.name,
    this.section,
    required this.isActive,
    this.subjects,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String? section;
  final bool isActive;
  final List<SubjectModel>? subjects;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => section != null ? '$name $section' : name;

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'] as List<dynamic>?;
    return ClassModel(
      id: _asString(json['id']),
      name: json['name'] as String,
      section: json['section'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      subjects: rawSubjects
          ?.map((e) => SubjectModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'section': section,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'section': section,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

  ClassModel copyWith({
    String? id,
    String? name,
    String? section,
    bool? isActive,
    List<SubjectModel>? subjects,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      section: section ?? this.section,
      isActive: isActive ?? this.isActive,
      subjects: subjects ?? this.subjects,
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

/// App model for `public.subjects`.
class SubjectModel {
  const SubjectModel({
    this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: _asString(json['id']),
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'description': description,
        'is_active': isActive,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'description': description,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

  SubjectModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
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
