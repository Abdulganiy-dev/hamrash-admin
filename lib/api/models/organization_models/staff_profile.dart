/// The signed-in person's own staff record at a school: the name and photo
/// the school knows them by.
class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.jobTitle,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String? jobTitle;

  String get fullName => '$firstName $lastName'.trim();

  static const columns = 'id, first_name, last_name, photo_url, job_title';

  factory StaffProfile.fromJson(Map<String, dynamic> json) => StaffProfile(
    id: json['id'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    photoUrl: json['photo_url'] as String?,
    jobTitle: json['job_title'] as String?,
  );
}
