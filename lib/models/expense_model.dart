import 'package:cloud_firestore/cloud_firestore.dart';

//-------------------- EXPENSE MODEL --------------------
class ExpenseModel {
  final String id;
  final String category; // e.g. Rent & Lease, Utilities, Maintenance...
  final String description; // vendor / note
  final double amount;
  final DateTime date;
  final String status; // 'paid' | 'pending'
  final String createdBy;

  ExpenseModel({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    required this.createdBy,
  });

  bool get isPaid => status == 'paid';

  //-------------------- FIRESTORE CONVERSION --------------------
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
      'createdBy': createdBy,
    };
  }

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    return ExpenseModel(
      id: id,
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'pending',
      createdBy: map['createdBy'] ?? '',
    );
  }
}

//-------------------- EXPENSE CATEGORY PRESETS --------------------
class ExpenseCategories {
  static const List<String> all = [
    'Rent & Lease',
    'Utilities',
    'Maintenance',
    'Supplies',
    'Services',
    'Other',
  ];
}
