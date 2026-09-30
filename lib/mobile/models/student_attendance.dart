class StudentAttendance {
  const StudentAttendance({
    required this.id,
    this.sessionId,
    this.studentId,
    this.studentCode,
    this.studentName,
    this.email,
    this.status = 'PRESENT',
    this.checkInTime,
    this.checkInIp,
    this.deviceInfo,
    this.room,
    this.className,
    this.subjectName,
    this.note,
  });

  final int id;
  final int? sessionId;
  final int? studentId;
  final String? studentCode;
  final String? studentName;
  final String? email;
  final String status;
  final DateTime? checkInTime;
  final String? checkInIp;
  final String? deviceInfo;
  final String? room;
  final String? className;
  final String? subjectName;
  final String? note;

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    int parseId(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return StudentAttendance(
      id: parseId(json['id']),
      sessionId: json['sessionId'] != null ? parseId(json['sessionId']) : null,
      studentId: json['studentId'] != null ? parseId(json['studentId']) : null,
      studentCode: json['studentCode']?.toString(),
      studentName: json['studentName']?.toString() ?? json['fullName']?.toString(),
      email: json['email']?.toString(),
      status: json['status']?.toString() ?? 'PRESENT',
      checkInTime: parseDate(json['checkInTime'] ?? json['createdAt']),
      checkInIp: json['checkInIp']?.toString(),
      deviceInfo: json['deviceInfo']?.toString(),
      room: json['room']?.toString(),
      className: json['className']?.toString(),
      subjectName: json['subjectName']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'studentId': studentId,
    'studentCode': studentCode,
    'studentName': studentName,
    'email': email,
    'status': status,
    'checkInTime': checkInTime?.toIso8601String(),
    'checkInIp': checkInIp,
    'deviceInfo': deviceInfo,
    'room': room,
    'className': className,
    'subjectName': subjectName,
    'note': note,
  };
}
