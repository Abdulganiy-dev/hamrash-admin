import 'package:hamrash_admin/core/utils/phone_format.dart';

/// A parent already in the school, found by phone while adding a student.
/// Read with the first names of their children so the row can say
/// "Parent of Tobenna".
class ParentMatch {
  const ParentMatch({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.title,
    this.photoUrl,
    this.childrenNames = const [],
  });

  final String id;
  final String? title;
  final String firstName;
  final String lastName;

  /// As saved: `+2348035550142`, `08035550142`, `0803 555 0142`, …
  final String phone;
  final String? photoUrl;

  /// First names of the students they are already linked to.
  final List<String> childrenNames;

  /// The parent row plus their children's names, for StudentService. One
  /// request: `student_parents` and `students` are embedded.
  static const columns =
      'id,title,first_name,last_name,phone,photo_url,'
      'student_parents!student_parents_parent_fkey('
      'students!student_parents_student_fkey(first_name))';

  factory ParentMatch.fromJson(Map<String, dynamic> json) {
    final links = json['student_parents'];
    final names = <String>[
      if (links is List)
        for (final link in links)
          if (link is Map<String, dynamic>)
            if (_one(link['students'])?['first_name'] case final String name
                when name.trim().isNotEmpty)
              name.trim(),
    ];
    return ParentMatch(
      id: json['id'] as String,
      title: _text(json['title']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: _text(json['photo_url']),
      childrenNames: names,
    );
  }

  /// "Ngozi Okafor".
  String get fullName => '$firstName $lastName'.trim();

  /// "Mrs Ngozi Okafor", or the name alone without a title.
  String get displayName => [?title, fullName].join(' ').trim();

  /// "Mrs Okafor", for "Use Mrs Okafor". Falls back to the first name.
  String get shortName => title == null ? firstName : '$title $lastName';

  /// The digits after +234, so numbers saved in any format compare equal.
  String get phoneDigits => PhoneFormat.digitsAfterPrefix(phone);

  /// "Parent of Tobenna", "Parent of Tobenna and Ada", "Parent of Tobenna
  /// and 2 others", or the phone number when they have no child here yet.
  String get caption {
    final names = childrenNames;
    return switch (names.length) {
      0 => PhoneFormat.nationalDisplay(phone),
      1 => 'Parent of ${names.first}',
      2 => 'Parent of ${names.first} and ${names.last}',
      _ => 'Parent of ${names.first} and ${names.length - 1} others',
    };
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// PostgREST gives a many-to-one embed as an object, but a list when the
  /// relationship is ambiguous; take the first either way.
  static Map<String, dynamic>? _one(Object? value) => switch (value) {
    final Map<String, dynamic> map => map,
    [final Map<String, dynamic> first, ...] => first,
    _ => null,
  };
}
