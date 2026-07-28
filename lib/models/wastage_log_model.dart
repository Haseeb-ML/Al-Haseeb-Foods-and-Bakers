class WastageLogModel {
  final String id;
  final String userId;
  final String userName;
  final String productName;
  final int quantity;
  final String reason; // e.g., Expired, Damaged, Spoiled
  final DateTime createdAt;

  WastageLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.productName,
    required this.quantity,
    required this.reason,
    required this.createdAt,
  });

  factory WastageLogModel.fromMap(Map<String, dynamic> map, String id) {
    return WastageLogModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      reason: map['reason'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'productName': productName,
      'quantity': quantity,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
