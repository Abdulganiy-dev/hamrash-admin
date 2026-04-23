import 'package:flutter/material.dart';
import 'package:hamrash_admin/resources/app_colors.dart';

class HomeAttendanceGreeting extends StatelessWidget {
  const HomeAttendanceGreeting({
    required this.greeting,
    required this.fullName,
    super.key,
  });

  final String greeting;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseStyle = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontWeight: FontWeight.w700, fontSize: 24);

    final mutedColor = isLight ? LightColors.textTextMute : DarkColors.textTextMute;
    final highlightColor = isLight
        ? LightColors.textTextInverted
        : DarkColors.textTextInverted;

    return RichText(
      text: TextSpan(
        style: baseStyle.copyWith(color: mutedColor),
        children: [
          TextSpan(text: '$greeting, '),
          TextSpan(text: fullName, style: TextStyle(color: highlightColor)),
          const TextSpan(text: '. Here is your '),
          TextSpan(
            text: 'attendance report',
            style: TextStyle(color: highlightColor),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
