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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return UrgentAlertModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> markAsRead(String docId) async {
    await _alertsRef.doc(docId).update({'isRead': true});
  }
}
