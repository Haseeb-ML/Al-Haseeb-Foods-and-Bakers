import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';

//-------------------- ATTENDANCE SERVICE --------------------
class AttendanceService {
  final CollectionReference _attendanceRef =
      FirebaseFirestore.instance.collection('attendance');

  // Helper to get YYYY-MM-DD string
  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  //-------------------- CLOCK IN --------------------
  Future<void> clockIn(String userId, String userName) async {
    final todayStr = _getTodayDateString();
    final query = await _attendanceRef
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: todayStr)
        .get();

    if (query.docs.isNotEmpty) {
      return; // Already clocked in today
    }

    final now = DateTime.now();
    // Default late threshold: 9:30 AM
    String status = 'Present';
    if (now.hour > 9 || (now.hour == 9 && now.minute > 30)) {
      status = 'Late';
    }

    final newDoc = _attendanceRef.doc();
    final model = AttendanceModel(
      id: newDoc.id,
      userId: userId,
      userName: userName,
      date: todayStr,
      clockIn: now,
      status: status,
    );

    await newDoc.set(model.toMap());
  }

  //-------------------- CLOCK OUT --------------------
  Future<void> clockOut(String userId) async {
    final todayStr = _getTodayDateString();
    final query = await _attendanceRef
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: todayStr)
        .get();

    if (query.docs.isEmpty) return;

    final docId = query.docs.first.id;
    await _attendanceRef.doc(docId).update({
      'clockOut': DateTime.now().toIso8601String(),
    });
  }

  //-------------------- GET TODAY ATTENDANCE (Stream) --------------------
  Stream<AttendanceModel?> getTodayAttendance(String userId) {
    final todayStr = _getTodayDateString();
    return _attendanceRef
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: todayStr)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  //-------------------- GET USER ATTENDANCE HISTORY --------------------
  Stream<List<AttendanceModel>> getAttendanceHistory(String userId) {
    return _attendanceRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList()
          ..sort((a, b) => b.clockIn.compareTo(a.clockIn)));
  }

  //-------------------- GET ALL STAFF ATTENDANCE HISTORY (Admin) --------------------
  Stream<List<AttendanceModel>> getAllAttendanceHistory() {
    return _attendanceRef
        .orderBy('clockIn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
