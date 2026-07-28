class UrgentAlertModel {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  UrgentAlertModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory UrgentAlertModel.fromMap(Map<String, dynamic> map, String id) {
    return UrgentAlertModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
