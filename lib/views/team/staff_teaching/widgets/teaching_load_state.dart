import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/constants/spacing_constants.dart';
import 'package:hamrash_admin/core/widgets/app_spinner.dart';
import 'package:hamrash_admin/core/widgets/app_text.dart';
import 'package:hamrash_admin/core/widgets/button/app_button_variants.dart';
import 'package:hamrash_admin/views/team/staff_teaching/teaching_setup_view_model.dart';
import 'package:hamrash_admin/views/team/staff_teaching/widgets/teaching_note.dart';

/// What a teaching sheet's body shows while its classes load, or when they
/// couldn't be loaded.
class TeachingLoadState extends StatelessWidget {
  const TeachingLoadState({
    super.key,
    required this.failed,
    required this.message,
    required this.onRetry,
  });

  final bool failed;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!failed) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: AppSpinner()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TeachingNote(note: message, tone: TeachingTone.error),
        const SizedBox(height: AppSpacing.md),
        AppSecondaryButton(
          onPressed: onRetry,
          child: const AppText('Try again'),
        ),
      ],
    );
  }
}
