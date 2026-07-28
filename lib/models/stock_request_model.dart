class StockRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String itemName; // e.g., Flour, Sugar, Cake Boxes
  final double quantity;
  final String unit; // e.g., kg, bags, pcs
  final String status; // Pending, Approved, Rejected
  final DateTime createdAt;

  StockRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.createdAt,
  });

  factory StockRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return StockRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'pcs',
      status: map['status'] ?? 'Pending',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
