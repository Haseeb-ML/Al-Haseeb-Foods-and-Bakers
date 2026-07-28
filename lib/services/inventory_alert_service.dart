import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_request_model.dart';
import '../models/wastage_log_model.dart';

class InventoryAlertService {
  final CollectionReference _requestsRef = FirebaseFirestore.instance.collection('stock_requests');
  final CollectionReference _wastageRef = FirebaseFirestore.instance.collection('wastage_logs');

  //-------------------- STOCK REQUESTS --------------------
  Future<void> submitStockRequest(StockRequestModel request) async {
    await _requestsRef.add(request.toMap());
  }

  Stream<List<StockRequestModel>> getStockRequests() {
    return _requestsRef.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) {
        return StockRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateRequestStatus(String docId, String status) async {
    await _requestsRef.doc(docId).update({'status': status});
  }

  //-------------------- WASTAGE LOGS --------------------
  Future<void> submitWastageLog(WastageLogModel log) async {
    await _wastageRef.add(log.toMap());
  }

  Stream<List<WastageLogModel>> getWastageLogs() {
    return _wastageRef.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) {
        return WastageLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
