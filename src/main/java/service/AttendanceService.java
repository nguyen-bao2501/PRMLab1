package  service;

import  dto.request.CheckInRequest;
import  dto.response.AttendanceResponse;
import  entity.Attendance;
import  entity.Session;
import  entity.User;
import  exception.ApiException;
import  exception.ErrorCode;
import  repository.AttendanceRepository;
import  repository.EnrollmentRepository;
import  repository.SessionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AttendanceService {

    private final AttendanceRepository attendanceRepository;
    private final SessionRepository sessionRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final QrTokenService qrTokenService;
    private final SessionService sessionService;

    @Transactional
    public AttendanceResponse checkIn(CheckInRequest req, User student, String ip) {
        // 1. QR token còn hạn không?
        Long sessionId = qrTokenService.resolveSessionId(req.getQrToken());
        if (sessionId == null) {
            throw new ApiException(ErrorCode.QR_EXPIRED);
        }

        // 2. Session tồn tại và đang mở?
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));

        if (session.getStatus() != Session.Status.OPEN) {
            throw new ApiException(ErrorCode.SESSION_CLOSED);
        }
        if (session.getQrExpiresAt() == null || !Instant.now().isBefore(session.getQrExpiresAt())) {
            sessionService.closeAndMarkAbsent(session);
            throw new ApiException(ErrorCode.QR_EXPIRED);
        }

        // 3. ⭐ Check user có trong roster của lớp không?
        Long classId = session.getClassRoom().getId();
        boolean inRoster = enrollmentRepository.existsByClassRoomIdAndStudentId(classId, student.getId());
        if (!inRoster) {
            log.warn("User {} ({}) không có trong roster lớp {}",
                    student.getId(), student.getEmail(), classId);
            throw new ApiException(ErrorCode.NOT_IN_ROSTER);
        }

        // 4. Đã điểm danh chưa?
        if (attendanceRepository.existsBySessionIdAndStudentId(sessionId, student.getId())) {
            throw new ApiException(ErrorCode.ALREADY_CHECKED_IN);
        }

        // 5. Ghi nhận
        Attendance a = Attendance.builder()
                .session(session)
                .student(student)
                .status(Attendance.Status.PRESENT)
                .markCode("A")
                .source("APP")
                .ipAddress(ip)
                .latitude(req.getLatitude())
                .longitude(req.getLongitude())
                .deviceInfo(req.getDeviceInfo())
                .build();
        attendanceRepository.save(a);

        log.info("Check-in OK: student={} session={}", student.getEmail(), sessionId);
        return toResponse(a);
    }

    public List<AttendanceResponse> listBySession(Long sessionId, User teacher) {
        Session s = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));
        if (!s.getClassRoom().getTeacher().getId().equals(teacher.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN);
        }
        return attendanceRepository.findBySessionId(sessionId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public List<AttendanceResponse> listByStudent(User student) {
        return attendanceRepository.findByStudentIdOrderByCheckInTimeDesc(student.getId())
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    private AttendanceResponse toResponse(Attendance a) {
        return AttendanceResponse.builder()
                .id(a.getId())
                .sessionId(a.getSession().getId())
                .studentId(a.getStudent().getId())
                .studentName(a.getStudent().getFullName())
                .studentCode(a.getStudent().getStudentCode())
                .email(a.getStudent().getEmail())
                .status(a.getStatus().name())
                .markCode(a.getMarkCode())
                .checkInTime(a.getCheckInTime())
                .ipAddress(a.getIpAddress())
                .build();
    }
}
