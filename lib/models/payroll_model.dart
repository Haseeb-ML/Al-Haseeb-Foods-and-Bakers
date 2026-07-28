//-------------------- PAYROLL MODEL --------------------
class PayrollModel {
  final String id;
  final String userId;
  final String userName;
  final String month; // e.g. "July 2026"
  final double baseSalary;
  final double bonus;
  final double deductions;
  final double netPaid;
  final DateTime paidAt;
  final String status; // "Paid"

  PayrollModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.month,
    required this.baseSalary,
    required this.bonus,
    required this.deductions,
    required this.netPaid,
    required this.paidAt,
    required this.status,
  });

  //-------------------- FIRESTORE -> MODEL --------------------
  factory PayrollModel.fromMap(Map<String, dynamic> map, String id) {
    return PayrollModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      month: map['month'] ?? '',
      baseSalary: (map['baseSalary'] ?? 0.0).toDouble(),
      bonus: (map['bonus'] ?? 0.0).toDouble(),
      deductions: (map['deductions'] ?? 0.0).toDouble(),
      netPaid: (map['netPaid'] ?? 0.0).toDouble(),
      paidAt: map['paidAt'] != null
          ? DateTime.parse(map['paidAt'])
          : DateTime.now(),
      status: map['status'] ?? 'Paid',
    );
  }

  //-------------------- MODEL -> FIRESTORE --------------------
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'month': month,
      'baseSalary': baseSalary,
      'bonus': bonus,
      'deductions': deductions,
      'netPaid': netPaid,
      'paidAt': paidAt.toIso8601String(),
      'status': status,
    };
  }
}
