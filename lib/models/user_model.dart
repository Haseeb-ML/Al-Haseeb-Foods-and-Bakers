//-------------------- USER MODEL --------------------
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "admin" or "staff"
  final String phone;
  final String profileImageUrl; // optional, empty rehne par fallback avatar dikhega
  final bool isActive;
  final double monthlySalary;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.profileImageUrl = '',
    this.isActive = true,
    this.monthlySalary = 0.0,
    required this.createdAt,
  });

  //-------------------- FIRESTORE -> MODEL --------------------
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'staff',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      monthlySalary: (map['monthlySalary'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  //-------------------- MODEL -> FIRESTORE --------------------
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'monthlySalary': monthlySalary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
}
