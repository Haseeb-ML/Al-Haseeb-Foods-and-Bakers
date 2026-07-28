//-------------------- CUSTOMER MODEL --------------------
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double balance;
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.balance = 0.0,
    required this.createdAt,
  });

  //-------------------- FIRESTORE -> MODEL --------------------
  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  //-------------------- MODEL -> FIRESTORE --------------------
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
