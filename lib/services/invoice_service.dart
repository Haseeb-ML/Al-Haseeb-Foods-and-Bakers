import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';

//-------------------- INVOICE SERVICE --------------------
class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //-------------------- CREATE INVOICE (Save + Reduce Stock) --------------------
  // Firestore Transaction use hoti hai taake stock aur invoice
  // dono ek sath, safely save hon (agar kahin fail ho to kuch save nahi hoga)
  Future<Map<String, String>> createInvoice({
    required String customerId,
    required String customerName,
    required List<InvoiceItem> items,
    required String createdBy,
    required double amountPaid,
    required double dueAmount,
    double discount = 0.0,
    double tax = 0.0,
    DateTime? dueDate,
  }) async {
    final invoiceRef = _firestore.collection('invoices').doc();
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

    await _firestore.runTransaction((transaction) async {
      //---------- STEP 1: Sab products ki current stock read karo ----------
      final productSnapshots = <String, DocumentSnapshot>{};
      for (var item in items) {
        final productRef = _firestore
            .collection('products')
            .doc(item.productId);
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) {
          throw 'Product "${item.productName}" no longer exists';
        }
        productSnapshots[item.productId] = snapshot;
      }

      //---------- STEP 2: Stock check karo (kahin negative na ho jaye) ----------
      for (var item in items) {
        final currentStock =
            (productSnapshots[item.productId]!.data() as Map)['stockQty']
                as int? ??
            0;
        if (currentStock < item.quantity) {
          throw 'Not enough stock for "${item.productName}" (only $currentStock left)';
        }
      }

      //---------- STEP 3: Stock reduce karo ----------
      for (var item in items) {
        final productRef = _firestore
            .collection('products')
            .doc(item.productId);
        transaction.update(productRef, {
          'stockQty': FieldValue.increment(-item.quantity),
        });
      }

      //---------- STEP 4: Increment customer balance if dueAmount exists ----------
      if (dueAmount > 0) {
        final customerRef = _firestore.collection('customers').doc(customerId);
        transaction.update(customerRef, {
          'balance': FieldValue.increment(dueAmount),
        });
      }

      //---------- STEP 5: Invoice save karo ----------
      final subTotal = items.fold<double>(
        0,
        (sum, item) => sum + item.total,
      );
      final totalAmount = subTotal - discount + tax;
      final invoice = InvoiceModel(
        id: invoiceRef.id,
        invoiceNumber: invoiceNumber,
        customerId: customerId,
        customerName: customerName,
        items: items,
        totalAmount: totalAmount,
        amountPaid: amountPaid,
        dueAmount: dueAmount,
        createdBy: createdBy,
        date: DateTime.now(),
        discount: discount,
        tax: tax,
        dueDate: dueDate,
      );
      transaction.set(invoiceRef, invoice.toMap());
    });

    return {
      'id': invoiceRef.id,
      'invoiceNumber': invoiceNumber,
    };
  }

  //-------------------- GET ALL INVOICES (real-time, for Reports) --------------------
  Stream<List<InvoiceModel>> getInvoices() {
    return _firestore
        .collection('invoices')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  //-------------------- GET TODAY'S INVOICES --------------------
  Stream<List<InvoiceModel>> getTodayInvoices() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('invoices')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  //-------------------- GET INVOICES FOR A SPECIFIC CUSTOMER --------------------
  Stream<List<InvoiceModel>> getInvoicesForCustomer(String customerId) {
    return _firestore
        .collection('invoices')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
