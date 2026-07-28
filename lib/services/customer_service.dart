import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';

//-------------------- CUSTOMER SERVICE --------------------
class CustomerService {
  final CollectionReference _customersRef = FirebaseFirestore.instance
      .collection('customers');

  //-------------------- ADD CUSTOMER --------------------
  Future<void> addCustomer(CustomerModel customer) async {
    await _customersRef.add(customer.toMap());
  }

  //-------------------- UPDATE CUSTOMER --------------------
  Future<void> updateCustomer(String id, CustomerModel customer) async {
    await _customersRef.doc(id).update(customer.toMap());
  }

  //-------------------- DELETE CUSTOMER --------------------
  Future<void> deleteCustomer(String id) async {
    await _customersRef.doc(id).delete();
  }

  //-------------------- GET ALL CUSTOMERS (real-time stream) --------------------
  Stream<List<CustomerModel>> getCustomers() {
    return _customersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CustomerModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  //-------------------- RECEIVE PAYMENT / RECOVER CREDIT (FIFO Invoice Allocation) --------------------
  Future<void> receivePayment({
    required String customerId,
    required double amount,
    required String receivedBy,
    String notes = '',
  }) async {
    // 1. Fetch pending invoices BEFORE the transaction starts
    final invoicesQuery = await FirebaseFirestore.instance
        .collection('invoices')
        .where('customerId', isEqualTo: customerId)
        .get();

    // Filter and sort in memory by date ascending (oldest first)
    final pendingInvoices = invoicesQuery.docs
        .map((doc) => InvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((inv) => inv.dueAmount > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // 2. Perform transaction writes
    final customerRef = _customersRef.doc(customerId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(customerRef);
      if (!snap.exists) return;
      final currentBalance = (snap.data() as Map<String, dynamic>?)?['balance'] as num? ?? 0.0;
      final newBalance = (currentBalance - amount).clamp(0.0, double.infinity);
      transaction.update(customerRef, {'balance': newBalance});

      double remainingPayment = amount;
      for (var invoice in pendingInvoices) {
        if (remainingPayment <= 0) break;

        final double due = invoice.dueAmount;
        final double paymentToInvoice = remainingPayment >= due ? due : remainingPayment;

        final invoiceRef = FirebaseFirestore.instance.collection('invoices').doc(invoice.id);
        transaction.update(invoiceRef, {
          'dueAmount': due - paymentToInvoice,
          'amountPaid': invoice.amountPaid + paymentToInvoice,
        });

        remainingPayment -= paymentToInvoice;
      }

      final paymentRef = FirebaseFirestore.instance.collection('customer_payments').doc();
      transaction.set(paymentRef, {
        'id': paymentRef.id,
        'customerId': customerId,
        'amount': amount,
        'receivedBy': receivedBy,
        'notes': notes,
        'date': DateTime.now().toIso8601String(),
      });
    });
  }

  //-------------------- RECEIVE PAYMENT FOR SPECIFIC INVOICE --------------------
  Future<void> receivePaymentForInvoice({
    required String customerId,
    required String invoiceId,
    required double amount,
    required String receivedBy,
    String notes = '',
  }) async {
    final customerRef = _customersRef.doc(customerId);
    final invoiceRef = FirebaseFirestore.instance.collection('invoices').doc(invoiceId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Perform all reads first (Firestore transactions require all reads before all writes)
      final customerSnap = await transaction.get(customerRef);
      final invoiceSnap = await transaction.get(invoiceRef);

      // 2. Perform all writes
      if (customerSnap.exists) {
        final currentBalance = (customerSnap.data() as Map<String, dynamic>?)?['balance'] as num? ?? 0.0;
        final newBalance = (currentBalance - amount).clamp(0.0, double.infinity);
        transaction.update(customerRef, {'balance': newBalance});
      }

      if (invoiceSnap.exists) {
        final invoice = InvoiceModel.fromMap(invoiceSnap.data() as Map<String, dynamic>, invoiceSnap.id);
        final newDue = (invoice.dueAmount - amount).clamp(0.0, double.infinity);
        final newPaid = invoice.amountPaid + amount;
        transaction.update(invoiceRef, {
          'dueAmount': newDue,
          'amountPaid': newPaid,
        });
      }

      // 3. Save payment log
      final paymentRef = FirebaseFirestore.instance.collection('customer_payments').doc();
      transaction.set(paymentRef, {
        'id': paymentRef.id,
        'customerId': customerId,
        'amount': amount,
        'receivedBy': receivedBy,
        'notes': notes,
        'date': DateTime.now().toIso8601String(),
      });
    });
  }

  //-------------------- UPDATE BALANCE --------------------
  Future<void> updateBalance(String customerId, double balanceDelta) async {
    await _customersRef.doc(customerId).update({
      'balance': FieldValue.increment(balanceDelta),
    });
  }
}
