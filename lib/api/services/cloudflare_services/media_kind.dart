/// What a Cloudflare image or video is for. The `media-upload` edge function
/// only accepts the kinds this app is allowed, and puts them in the Cloudflare
/// id prefix and labels.
enum MediaKind {
  /// A school's logo, stored as `organizations.logo_url` and `logo_id`.
  schoolLogo('school-logos'),

  /// `staff.photo_url` and `photo_id`.
  staffPhoto('staff-photos'),

  /// `students.photo_url` and `photo_id`.
  studentPhoto('student-photos'),

  /// `parents.photo_url` and `photo_id`.
  parentPhoto('parent-photos');

  const MediaKind(this.path);
  final String path;

  /// This app's name in the shared Cloudflare account. Must match the
  /// allow-list in `supabase/functions/_shared/media_upload.mjs`.
  static const String appName = 'hamrash-admin';
}
