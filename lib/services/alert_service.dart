import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/urgent_alert_model.dart';

class AlertService {
  final CollectionReference _alertsRef = FirebaseFirestore.instance.collection('urgent_alerts');

  Future<void> sendUrgentAlert(UrgentAlertModel alert) async {
    await _alertsRef.add(alert.toMap());
  }

  Stream<List<UrgentAlertModel>> getActiveAlerts() {
    return _alertsRef
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        return UrgentAlertModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Sort in memory by createdAt descending to bypass composite index requirement
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markAsRead(String docId) async {
    await _alertsRef.doc(docId).update({'isRead': true});
  }
}
