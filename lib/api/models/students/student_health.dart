/// The blood groups `student_private_details.blood_group` accepts
/// (migration 07's check). Anything else is refused with 23514.
abstract final class BloodGroups {
  static const values = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
}

/// The genotypes `student_private_details.genotype` accepts (migration 07's
/// check). Anything else is refused with 23514.
abstract final class Genotypes {
  static const values = ['AA', 'AS', 'AC', 'SS', 'SC', 'CC'];
}
