class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String faculty;
  final bool isApproved;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.faculty,
    required this.isApproved,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'student',
      faculty: json['faculty'] ?? '',
      isApproved: json['is_approved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'faculty': faculty,
      'is_approved': isApproved,
    };
  }

  bool get isStudent => role == 'student';
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get canManageDocuments => isAdmin || isSuperAdmin;
  bool get canApproveAdmins => isSuperAdmin;
}
