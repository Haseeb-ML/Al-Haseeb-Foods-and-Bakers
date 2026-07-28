import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

//-------------------- EXPENSE SERVICE --------------------
class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //-------------------- ADD EXPENSE --------------------
  Future<void> addExpense(ExpenseModel expense) async {
    await _firestore.collection('expenses').add(expense.toMap());
  }

  //-------------------- UPDATE EXPENSE --------------------
  Future<void> updateExpense(String id, ExpenseModel expense) async {
    await _firestore.collection('expenses').doc(id).update(expense.toMap());
  }

  //-------------------- DELETE EXPENSE --------------------
  Future<void> deleteExpense(String id) async {
    await _firestore.collection('expenses').doc(id).delete();
  }

  //-------------------- GET ALL EXPENSES (live stream, newest first) --------------------
  Stream<List<ExpenseModel>> getExpenses() {
    return _firestore
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
