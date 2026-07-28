import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payroll_model.dart';

//-------------------- PAYROLL SERVICE --------------------
class PayrollService {
  final CollectionReference _payrollRef =
      FirebaseFirestore.instance.collection('payroll');
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  //-------------------- PAY SALARY --------------------
  Future<void> paySalary(PayrollModel payroll) async {
    final newDoc = _payrollRef.doc();
    final toSave = PayrollModel(
      id: newDoc.id,
      userId: payroll.userId,
      userName: payroll.userName,
      month: payroll.month,
      baseSalary: payroll.baseSalary,
      bonus: payroll.bonus,
      deductions: payroll.deductions,
      netPaid: payroll.netPaid,
      paidAt: DateTime.now(),
      status: 'Paid',
    );
    await newDoc.set(toSave.toMap());
  }

  //-------------------- GET EMPLOYEE PAYROLL HISTORY --------------------
  Stream<List<PayrollModel>> getPayrollHistory(String userId) {
    return _payrollRef
        .where('userId', isEqualTo: userId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                PayrollModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  //-------------------- GET ALL PAYROLL RECORDS (Admin) --------------------
  Stream<List<PayrollModel>> getAllPayrollHistory() {
    return _payrollRef
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                PayrollModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  //-------------------- UPDATE STAFF BASE SALARY --------------------
  Future<void> updateBaseSalary(String userId, double salary) async {
    await _usersRef.doc(userId).update({
      'monthlySalary': salary,
    });
  }
}
