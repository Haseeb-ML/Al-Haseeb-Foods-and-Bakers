//-------------------- ATTENDANCE MODEL --------------------
class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final String date; // YYYY-MM-DD
  final DateTime clockIn;
  final DateTime? clockOut;
  final String status; // "Present" or "Late"

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    required this.clockIn,
    this.clockOut,
    required this.status,
  });

  //-------------------- FIRESTORE -> MODEL --------------------
  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      date: map['date'] ?? '',
      clockIn: map['clockIn'] != null
          ? DateTime.parse(map['clockIn'])
          : DateTime.now(),
      clockOut: map['clockOut'] != null
          ? DateTime.parse(map['clockOut'])
          : null,
      status: map['status'] ?? 'Present',
    );
  }

  //-------------------- MODEL -> FIRESTORE --------------------
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'date': date,
      'clockIn': clockIn.toIso8601String(),
      'clockOut': clockOut?.toIso8601String(),
      'status': status,
    };
  }
}
