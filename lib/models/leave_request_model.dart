class LeaveRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String leaveType; // Sick, Casual, Shift Exchange
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // Pending, Approved, Rejected
  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return LeaveRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      leaveType: map['leaveType'] ?? 'Sick',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : DateTime.now(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'Pending',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
