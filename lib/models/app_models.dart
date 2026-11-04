class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = 'LECTURER',
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? 'Giảng viên',
      photoUrl: json['photoUrl']?.toString(),
      role: json['role']?.toString() ?? 'LECTURER',
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role,
  };
}

class ClassModel {
  const ClassModel({
    required this.id,
    required this.subjectCode,
    required this.className,
    required this.semester,
    required this.studentCount,
    required this.sessionCount,
    this.sheetUrl,
    this.sheetTab,
    this.isLinkedSheet = false,
  });

  final String id;
  final String subjectCode;
  final String className;
  final String semester;
  final int studentCount;
  final int sessionCount;
  final String? sheetUrl;
  final String? sheetTab;
  final bool isLinkedSheet;

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? json['courseCode']?.toString() ?? 'PRM393',
      className: json['className']?.toString() ?? json['code']?.toString() ?? 'SE1917',
      semester: json['semester']?.toString() ?? 'FA2026',
      studentCount: (json['studentCount'] as num?)?.toInt() ?? (json['students'] as List?)?.length ?? 35,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 8,
      sheetUrl: json['sheetUrl']?.toString(),
      sheetTab: json['sheetTab']?.toString() ?? '12_PRM393_SE1917',
      isLinkedSheet: json['isLinkedSheet'] == true || (json['sheetUrl'] != null && json['sheetUrl'].toString().isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectCode': subjectCode,
    'className': className,
    'semester': semester,
    'studentCount': studentCount,
    'sessionCount': sessionCount,
    'sheetUrl': sheetUrl,
    'sheetTab': sheetTab,
    'isLinkedSheet': isLinkedSheet,
  };
}

enum SessionStatus {
  active, // Đang điểm danh
  upcoming, // Chưa đến giờ / Chưa mở
  completed, // Đã kết thúc
}

class SessionModel {
  const SessionModel({
    required this.id,
    required this.classId,
    required this.subjectCode,
    required this.className,
    required this.room,
    required this.slot,
    required this.timeRange,
    required this.date,
    required this.dayOfWeek,
    required this.status,
    this.qrToken,
    this.attendedCount = 0,
    this.totalCount = 0,
  });

  final String id;
  final String classId;
  final String subjectCode;
  final String className;
  final String room;
  final int slot;
  final String timeRange;
  final String date; // dd/MM/yyyy
  final String dayOfWeek; // Thứ 2, Thứ 7, CN...
  final SessionStatus status;
  final String? qrToken;
  final int attendedCount;
  final int totalCount;

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    SessionStatus parsedStatus = SessionStatus.upcoming;
    final statusStr = json['status']?.toString().toUpperCase() ?? '';
    if (statusStr.contains('ACTIVE') || statusStr.contains('DANG_DIEM_DANH')) {
      parsedStatus = SessionStatus.active;
    } else if (statusStr.contains('COMPLETED') || statusStr.contains('KET_THUC')) {
      parsedStatus = SessionStatus.completed;
    }

    return SessionModel(
      id: json['id']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      subjectCode: json['subjectCode']?.toString() ?? 'PRM393',
      className: json['className']?.toString() ?? 'SE1917',
      room: json['room']?.toString() ?? 'A101',
      slot: (json['slot'] as num?)?.toInt() ?? 1,
      timeRange: json['timeRange']?.toString() ?? '07:00 – 09:15',
      date: json['date']?.toString() ?? '03/10/2026',
      dayOfWeek: json['dayOfWeek']?.toString() ?? 'T7',
      status: parsedStatus,
      qrToken: json['qrToken']?.toString(),
      attendedCount: (json['attendedCount'] as num?)?.toInt() ?? 28,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 35,
    );
  }
}

class StudentAttendanceItem {
  const StudentAttendanceItem({
    required this.studentId,
    required this.name,
    required this.isPresent,
    this.checkInTime,
    this.note,
  });

  final String studentId;
  final String name;
  final bool isPresent;
  final String? checkInTime;
  final String? note;

  StudentAttendanceItem copyWith({
    bool? isPresent,
    String? checkInTime,
    String? note,
  }) {
    return StudentAttendanceItem(
      studentId: studentId,
      name: name,
      isPresent: isPresent ?? this.isPresent,
      checkInTime: checkInTime ?? this.checkInTime,
      note: note ?? this.note,
    );
  }
}

class AbsentSummaryItem {
  const AbsentSummaryItem({
    required this.studentId,
    required this.name,
    required this.absentCount,
    required this.totalSessions,
    required this.percent,
  });

  final String studentId;
  final String name;
  final int absentCount;
  final int totalSessions;
  final double percent;
}
