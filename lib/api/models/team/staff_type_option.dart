/// The two values `staff_type` accepts, with the labels the app shows for
/// them ("Teaching" and "Non-teaching", the same as `StaffTypeFilter`).
///
/// A person's job title is not their staff type: a principal or an admin who
/// also teaches is still teaching staff, so the Add Staff form asks for the
/// type itself and only starts from the job title's default
/// (`StaffJobTitleOption.staffType`).
enum StaffTypeOption {
  teaching('teaching', 'Teaching'),
  nonTeaching('non_teaching', 'Non-teaching');

  const StaffTypeOption(this.value, this.label);

  /// What goes in `staff.staff_type`.
  final String value;

  /// What the picker shows.
  final String label;
}
