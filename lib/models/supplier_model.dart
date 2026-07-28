//-------------------- SUPPLIER MODEL --------------------
class SupplierModel {
  final String id;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String address;
  final double payableBalance; // Amount we owe to supplier
  final DateTime createdAt;

  SupplierModel({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.address,
    this.payableBalance = 0.0,
    required this.createdAt,
  });

  //-------------------- FIRESTORE -> MODEL --------------------
  factory SupplierModel.fromMap(String id, Map<String, dynamic> map) {
    return SupplierModel(
      id: id,
      companyName: map['companyName'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      payableBalance: (map['payableBalance'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  //-------------------- MODEL -> FIRESTORE --------------------
  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'contactPerson': contactPerson,
      'phone': phone,
      'address': address,
      'payableBalance': payableBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
