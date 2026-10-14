/// A school's structure: sections (Nursery, Primary, …) hold classes
/// (Primary 1, …), and classes hold arms (A, B, Gold, …), the groups pupils
/// actually sit in.
class SchoolSection {
  const SchoolSection({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.classes,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  /// In teaching order.
  final List<SchoolClass> classes;

  /// Sections with their classes and arms, for [ClassStructureService].
  static const columns =
      'id,name,sort_order,is_active,'
      'classes!classes_section_fkey(id,section_id,name,sort_order,is_graduating_class,is_active,'
      'class_arms!class_arms_class_fkey(id,class_id,name,is_active,created_at))';

  factory SchoolSection.fromJson(Map<String, dynamic> json) {
    final classes =
        (json['classes'] as List<dynamic>? ?? const [])
            .map((row) => SchoolClass.fromJson(row as Map<String, dynamic>))
            .toList()
          ..sort((a, b) {
            final order = a.sortOrder.compareTo(b.sortOrder);
            return order != 0 ? order : a.name.compareTo(b.name);
          });
    return SchoolSection(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int,
      isActive: json['is_active'] as bool,
      classes: classes,
    );
  }

  /// The next free [SchoolClass.sortOrder] for a class added at the end.
  int get nextClassOrder => classes.isEmpty ? 1 : classes.last.sortOrder + 1;
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.sectionId,
    required this.name,
    required this.sortOrder,
    required this.isGraduating,
    required this.isActive,
    required this.arms,
  });

  final String id;
  final String sectionId;
  final String name;
  final int sortOrder;

  /// Students promoted out of this class graduate.
  final bool isGraduating;

  /// Switched-off classes stay in records but take no new students.
  final bool isActive;

  /// In the order they were added.
  final List<ClassArm> arms;

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
    id: json['id'] as String,
    sectionId: json['section_id'] as String,
    name: json['name'] as String,
    sortOrder: json['sort_order'] as int,
    isGraduating: json['is_graduating_class'] as bool,
    isActive: json['is_active'] as bool,
    arms:
        (json['class_arms'] as List<dynamic>? ?? const [])
            .map((row) => ClassArm.fromJson(row as Map<String, dynamic>))
            .toList()
          ..sort((a, b) {
            final added = a.createdAt.compareTo(b.createdAt);
            return added != 0 ? added : a.name.compareTo(b.name);
          }),
  );

  bool get hasArms => arms.isNotEmpty;

  /// "Primary 1A" for [arm] "A", "Primary 1 Gold" for "Gold".
  String armLabel(String arm) => fullArmName(name, arm);
}

class ClassArm {
  const ClassArm({
    required this.id,
    required this.classId,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String classId;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  factory ClassArm.fromJson(Map<String, dynamic> json) => ClassArm(
    id: json['id'] as String,
    classId: json['class_id'] as String,
    name: json['name'] as String,
    isActive: json['is_active'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

/// How an arm reads with its class: single letters and numbers join the
/// class name ("JSS 1A"), words get a space ("JSS 1 Gold").
String fullArmName(String className, String arm) =>
    arm.length == 1 ? '$className$arm' : '$className $arm';
