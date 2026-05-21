import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.student,
    required this.size,
  });

  final StudentModel student;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = student.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImageWidget(
        imageUrl: url,
        width: size,
        height: size,
        borderRadius: size / 2,
        fit: BoxFit.cover,
      );
    }
    return _InitialsAvatar(student: student, size: size);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.student, required this.size});

  final StudentModel student;
  final double size;

  static const _colors = [
    Color(0xFF7E57C2),
    Color(0xFF26A69A),
    Color(0xFF66BB6A),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFFFF7043),
    Color(0xFF8D6E63),
  ];

  Color get _color {
    final name = student.firstName + student.lastName;
    final index =
        name.codeUnits.fold(0, (sum, c) => sum + c) % _colors.length;
    return _colors[index];
  }

  String get _initials {
    final f = student.firstName.isNotEmpty ? student.firstName[0] : '';
    final l = student.lastName.isNotEmpty ? student.lastName[0] : '';
    return (f + l).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _color),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}
