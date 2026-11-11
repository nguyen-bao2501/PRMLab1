package service;

import dto.request.CreateSessionRequest;
import dto.response.SessionResponse;
import entity.ClassRoom;
import entity.Session;
import entity.User;
import exception.ApiException;
import exception.ErrorCode;
import repository.AttendanceRepository;
import repository.ClassRepository;
import repository.EnrollmentRepository;
import repository.SessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.scheduling.annotation.Scheduled;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SessionService {

    @org.springframework.beans.factory.annotation.Value("${app.attendance.public-base-url:}")
    private String publicBaseUrl = "";

    @jakarta.annotation.PostConstruct
    void validatePublicUrl() {
        if (publicBaseUrl == null || publicBaseUrl.isBlank()) return;
        java.net.URI uri = java.net.URI.create(publicBaseUrl);
        if (uri.getHost() == null || uri.getScheme() == null
                || (!"https".equalsIgnoreCase(uri.getScheme())
                && !("http".equalsIgnoreCase(uri.getScheme())
                && ("localhost".equalsIgnoreCase(uri.getHost())
                || "127.0.0.1".equals(uri.getHost()))))) {
            throw new IllegalArgumentException(
                    "ATTENDANCE_PUBLIC_BASE_URL must be an HTTPS URL (localhost allowed for testing)");
        }
    }

    private final SessionRepository sessionRepository;
    private final ClassRepository classRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final AttendanceRepository attendanceRepository;
    private final QrTokenService qrTokenService;

    @Transactional
    public SessionResponse schedule(CreateSessionRequest req, User teacher) {
        ClassRoom cls = classRepository.findById(req.getClassId())
                .orElseThrow(() -> new ApiException(ErrorCode.CLASS_NOT_FOUND));
        if (!cls.getTeacher().getId().equals(teacher.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN);
        }
        if (req.getStartTime() == null || !req.getStartTime().isAfter(Instant.now())
                || req.getRoom() == null || req.getRoom().isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED);
        }
        if (sessionRepository.existsByClassRoomTeacherIdAndStatusNotAndStartTimeGreaterThanAndStartTimeLessThan(
                teacher.getId(), Session.Status.CANCELLED,
                req.getStartTime().minusSeconds(135 * 60),
                req.getStartTime().plusSeconds(135 * 60))) {
            throw new ApiException(ErrorCode.SCHEDULE_CONFLICT);
        }
        Session s = Session.builder().classRoom(cls)
                .sessionDate(req.getStartTime().atZone(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).toLocalDate())
                .startTime(req.getStartTime()).room(req.getRoom().trim())
                .status(Session.Status.SCHEDULED).build();
        sessionRepository.save(s);
        cls.setTotalSessions(cls.getTotalSessions() + 1);
        return toResponse(s, null, true);
    }

    @Transactional
    public SessionResponse open(Long id, User teacher) {
        Session s = sessionRepository.findForOpening(id)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));
        assertOwner(s, teacher);
        if (s.getStatus() != Session.Status.SCHEDULED && s.getStatus() != Session.Status.CLOSED) {
            throw new ApiException(ErrorCode.SESSION_CLOSED);
        }
        Instant now = Instant.now();
        java.time.LocalDate today = java.time.LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
        java.time.LocalDate sessionDay = s.getSessionDate() != null
                ? s.getSessionDate()
                : s.getStartTime().atZone(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).toLocalDate();
        if (now.isBefore(s.getStartTime()) || !sessionDay.equals(today)) {
            throw new ApiException(ErrorCode.ATTENDANCE_WINDOW, "Chỉ được phép mở điểm danh trong ngày của buổi học.");
        }
        s.setStatus(Session.Status.OPEN);
        s.setEndTime(null);
        s.setQrExpiresAt(now.plusSeconds(qrTokenService.getTtlSeconds()));
        return toResponse(s, qrTokenService.generateForSession(s.getId()), true);
    }

    @Transactional
    public SessionResponse create(CreateSessionRequest req, User teacher) {
        ClassRoom cls = classRepository.findById(req.getClassId())
                .orElseThrow(() -> new ApiException(ErrorCode.CLASS_NOT_FOUND));
        if (!cls.getTeacher().getId().equals(teacher.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN);
        }
        Session s = Session.builder()
                .classRoom(cls)
                .sessionDate(LocalDate.now())
                .startTime(req.getStartTime() != null ? req.getStartTime() : Instant.now())
                .qrExpiresAt(Instant.now().plusSeconds(qrTokenService.getTtlSeconds()))
                .room(req.getRoom())
                .status(Session.Status.OPEN)
                .build();
        sessionRepository.save(s);
        cls.setTotalSessions(cls.getTotalSessions() + 1);
        return toResponse(s, qrTokenService.generateForSession(s.getId()), true);
    }

    @Transactional
    public SessionResponse refreshQr(Long sessionId, User teacher) {
        Session s = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));
        assertOwner(s, teacher);
        if (s.getStatus() != Session.Status.OPEN && s.getStatus() != Session.Status.CLOSED) {
            throw new ApiException(ErrorCode.SESSION_CLOSED);
        }
        s.setStatus(Session.Status.OPEN);
        s.setEndTime(null);
        s.setQrExpiresAt(Instant.now().plusSeconds(qrTokenService.getTtlSeconds()));
        return toResponse(s, qrTokenService.generateForSession(s.getId()), false);
    }


    @Transactional
    public SessionResponse close(Long sessionId, User teacher) {
        Session s = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));
        assertOwner(s, teacher);
        closeAndMarkAbsent(s);
        return toResponse(s, null, false);
    }

    @Scheduled(fixedDelayString = "${app.attendance.expiration-check-ms:15000}")
    @Transactional
    public void closeExpiredSessions() {
        sessionRepository.findByStatusAndQrExpiresAtLessThanEqual(Session.Status.OPEN, Instant.now())
                .forEach(this::closeAndMarkAbsent);
    }

    @Transactional
    public void closeAndMarkAbsent(Session session) {
        if (session.getStatus() != Session.Status.OPEN) return;
        session.setStatus(Session.Status.CLOSED);
        session.setEndTime(Instant.now());
        enrollmentRepository.findByClassRoomId(session.getClassRoom().getId()).forEach(enrollment -> {
            if (!attendanceRepository.existsBySessionIdAndStudentId(
                    session.getId(), enrollment.getStudent().getId())) {
                attendanceRepository.save(entity.Attendance.builder()
                        .session(session)
                        .student(enrollment.getStudent())
                        .status(entity.Attendance.Status.ABSENT)
                        .markCode("AS")
                        .source("SYSTEM")
                        .note("QR het han hoac giao vien ket thuc diem danh")
                        .build());
            }
        });
    }

    public List<SessionResponse> listByClass(Long classId, User teacher) {
        ClassRoom cls = classRepository.findById(classId)
                .orElseThrow(() -> new ApiException(ErrorCode.CLASS_NOT_FOUND));
        if (!cls.getTeacher().getId().equals(teacher.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN);
        }
        return sessionRepository.findByClassRoomIdOrderBySessionDateDesc(classId)
                .stream().map(s -> toResponse(s, null, false)).collect(Collectors.toList());
    }

    public SessionResponse getById(Long id, User teacher) {
        Session s = sessionRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));
        assertOwner(s, teacher);
        return toResponse(s, null, true);
    }

    private void assertOwner(Session s, User teacher) {
        if (!s.getClassRoom().getTeacher().getId().equals(teacher.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN);
        }
    }

    private SessionResponse toResponse(Session s, String qrToken, boolean includeStats) {
        SessionResponse.SessionResponseBuilder b = SessionResponse.builder()
                .id(s.getId())
                .classId(s.getClassRoom().getId())
                .classCode(s.getClassRoom().getClassCode())
                .sessionDate(s.getSessionDate())
                .startTime(s.getStartTime())
                .endTime(s.getEndTime())
                .room(s.getRoom())
                .status(s.getStatus().name())
                .qrToken(qrToken)
                .qrUrl(qrToken == null ? null : buildCheckInUrl(qrToken))
                .qrExpiresAt(s.getQrExpiresAt());
        if (includeStats) {
            b.totalStudents(enrollmentRepository.countByClassRoomId(s.getClassRoom().getId()));
            b.checkedIn(attendanceRepository.countBySessionIdAndStatus(
                    s.getId(), entity.Attendance.Status.PRESENT)
                    + attendanceRepository.countBySessionIdAndStatus(
                    s.getId(), entity.Attendance.Status.LATE));
        }
        return b.build();
    }

    private String buildCheckInUrl(String qrToken) {
        String baseUrl = publicBaseUrl == null || publicBaseUrl.isBlank()
                ? "http://localhost:8080"
                : publicBaseUrl.replaceAll("/+$", "");
        return baseUrl + "/check-in.html#token="
                + java.net.URLEncoder.encode(qrToken, java.nio.charset.StandardCharsets.UTF_8);
    }
}
