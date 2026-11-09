import 'package:flutter/material.dart';
import 'package:hamrash_admin/core/bottomSheets/app_photo_options_sheet.dart';
import 'package:hamrash_admin/core/widgets/app_photo_field.dart';
import 'package:hamrash_admin/views/students/add_student/add_student_view_model.dart';
import 'package:hamrash_admin/views/students/add_student/photo_draft.dart';

/// An [AppPhotoField] for one of the wizard's photos: tapping it opens the
/// photo options (11.4) and hands the choice to the view model.
class WizardPhotoField extends StatelessWidget {
  const WizardPhotoField({
    super.key,
    required this.model,
    required this.draft,
    required this.name,
    required this.sheetTitle,
    this.title,
    this.emptyCaption = 'Optional',
    this.size = AppPhotoFieldSize.large,
  });

  final AddStudentViewModel model;
  final PhotoDraft draft;

  /// For the initials.
  final String name;

  /// "Photo of Chioma".
  final String sheetTitle;
  final String? title;
  final String emptyCaption;
  final AppPhotoFieldSize size;

  Future<void> _open(BuildContext context) async {
    if (draft.isUploading) return;
    final choice = await AppPhotoOptionsSheet.show(
      context,
      title: sheetTitle,
      canRemove: !draft.isEmpty,
      canRetry: draft.hasFailed,
    );
    if (choice == null) return;
    await model.applyPhotoChoice(draft, choice);
  }

  @override
  Widget build(BuildContext context) => AppPhotoField(
    name: name,
    title: title,
    status: draft.status,
    image: draft.preview,
    emptyCaption: emptyCaption,
    failedCaption:
        draft.failure ?? "Couldn't upload the photo. Check your connection.",
    size: size,
    onTap: () => _open(context),
  );
}
