/// The staff member's private details row, read only so the Change details
/// sheet can send every field back to `update_staff` unchanged.
class StaffPrivateDetails {
  const StaffPrivateDetails({
    this.dateOfBirth,
    this.address,
    this.stateOfOrigin,
    this.employmentDate,
    this.residenceState,
    this.residenceLga,
  });

  final DateTime? dateOfBirth;
  final String? address;
  final String? stateOfOrigin;
  final DateTime? employmentDate;

  /// Where they live now. Private like the home address.
  final String? residenceState;
  final String? residenceLga;

  static const columns =
      'date_of_birth,address,state_of_origin,employment_date,'
      'residence_state,residence_lga';

  factory StaffPrivateDetails.fromJson(Map<String, dynamic> json) =>
      StaffPrivateDetails(
        dateOfBirth: _date(json['date_of_birth']),
        address: json['address'] as String?,
        stateOfOrigin: json['state_of_origin'] as String?,
        employmentDate: _date(json['employment_date']),
        residenceState: json['residence_state'] as String?,
        residenceLga: json['residence_lga'] as String?,
      );

  static DateTime? _date(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.parse(value) : null;
}
