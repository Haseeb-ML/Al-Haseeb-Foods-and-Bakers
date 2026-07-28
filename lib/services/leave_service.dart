import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_request_model.dart';

class LeaveService {
  final CollectionReference _leavesRef = FirebaseFirestore.instance.collection('leave_requests');

  Future<void> submitLeaveRequest(LeaveRequestModel request) async {
    await _leavesRef.add(request.toMap());
  }

  Stream<List<LeaveRequestModel>> getLeaveRequests() {
    return _leavesRef.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) {
        return LeaveRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateRequestStatus(String docId, String status) async {
    await _leavesRef.doc(docId).update({'status': status});
  }
}
