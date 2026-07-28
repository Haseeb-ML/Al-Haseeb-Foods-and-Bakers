import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_model.dart';

//-------------------- SUPPLIER & STOCK-IN SERVICE --------------------
class SupplierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //-------------------- ADD SUPPLIER --------------------
  Future<void> addSupplier(SupplierModel supplier) async {
    await _firestore.collection('suppliers').add(supplier.toMap());
  }

  //-------------------- UPDATE SUPPLIER --------------------
  Future<void> updateSupplier(String id, SupplierModel supplier) async {
    await _firestore.collection('suppliers').doc(id).update(supplier.toMap());
  }

  //-------------------- DELETE SUPPLIER --------------------
  Future<void> deleteSupplier(String id) async {
    await _firestore.collection('suppliers').doc(id).delete();
  }

  //-------------------- GET ALL SUPPLIERS (Stream) --------------------
  Stream<List<SupplierModel>> getSuppliers() {
    return _firestore
        .collection('suppliers')
        .orderBy('companyName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupplierModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  //-------------------- RECORD STOCK-IN PURCHASE ORDER --------------------
  // Increases product stockQty in Firestore & updates Supplier balance
  Future<void> recordStockPurchase({
    required String supplierId,
    required String supplierName,
    required List<Map<String, dynamic>> items, // productId, name, qtyAdded, costPrice
    required double totalAmount,
    required double paidAmount,
  }) async {
    final batch = _firestore.batch();

    // 1. Log Purchase Record
    final purchaseRef = _firestore.collection('purchase_orders').doc();
    batch.set(purchaseRef, {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingBalance': totalAmount - paidAmount,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 2. Increment Product Stock for each item
    for (var item in items) {
      final productId = item['productId'] as String;
      final qtyAdded = (item['qtyAdded'] as num).toInt();
      final productRef = _firestore.collection('products').doc(productId);

      batch.update(productRef, {
        'stockQty': FieldValue.increment(qtyAdded),
      });
    }

    // 3. Update Supplier Payable Balance
    final remainingDues = totalAmount - paidAmount;
    if (supplierId.isNotEmpty) {
      final supplierRef = _firestore.collection('suppliers').doc(supplierId);
      batch.update(supplierRef, {
        'payableBalance': FieldValue.increment(remainingDues),
      });
    }

    await batch.commit();
  }
}
