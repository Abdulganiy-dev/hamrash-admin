/// App model for `public.admin_profiles`.
class AdminProfileModel {
  const AdminProfileModel({
   this.id,
    this.clerkId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.gender,
    this.avatarUrl,
    this.avatarUrlId,
    this.address,
    this.state,
    this.fcmToken,
    this.role,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? clerkId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? gender;
  final String? avatarUrl;
  final String? avatarUrlId;
  final String? address;
  final String? state;
  final String? fcmToken;
  final String? role;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminProfileModel.fromJson(Map<String, dynamic> json) {
    return AdminProfileModel(
      id: _asString(json['id']),
      clerkId: json['clerk_id'] as String?,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      gender: json['gender'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarUrlId: json['avatar_url_id'] as String?,
      address: json['address'] as String?,
      state: json['state'] as String?,
      fcmToken: json['fcm_token'] as String?,
      role: json['role'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: _parseDateTime(json['last_login_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        
        'clerk_id': clerkId,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'gender': gender,
        'avatar_url': avatarUrl,
        'avatar_url_id': avatarUrlId,
        'address': address,
        'state': state,
        'fcm_token': fcmToken,
        'role': role,
        'is_active': isActive,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static String _asString(dynamic v) => v is String ? v : v.toString();

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
