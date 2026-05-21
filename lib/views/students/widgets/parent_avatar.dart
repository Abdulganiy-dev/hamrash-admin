import 'package:flutter/material.dart';
import 'package:hamrash_admin/api/models/supabase_models/student_model.dart';
import 'package:hamrash_admin/widgets/cached_network_image_widget.dart';

class ParentAvatar extends StatelessWidget {
  const ParentAvatar({super.key, required this.parent, required this.size});

  final ParentModel parent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = parent.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImageWidget(
        imageUrl: url,
        width: size,
        height: size,
        borderRadius: size / 2,
        fit: BoxFit.cover,
      );
    }
    return _InitialsAvatar(parent: parent, size: size);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.parent, required this.size});

  final ParentModel parent;
  final double size;

  static const _colors = [
    Color(0xFF26A69A),
    Color(0xFF5C6BC0),
    Color(0xFFEC407A),
    Color(0xFFFFA726),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF8D6E63),
  ];

  Color get _color {
    final name = parent.firstName + parent.lastName;
    final index =
        name.codeUnits.fold(0, (sum, c) => sum + c) % _colors.length;
    return _colors[index];
  }

  String get _initials {
    final f = parent.firstName.isNotEmpty ? parent.firstName[0] : '';
    final l = parent.lastName.isNotEmpty ? parent.lastName[0] : '';
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
