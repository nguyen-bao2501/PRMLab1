package  service;

import  dto.request.CreateSessionRequest;
import  dto.response.SessionResponse;
import  entity.ClassRoom;
import  entity.Session;
import  entity.User;
import  exception.ApiException;
import  exception.ErrorCode;
import  repository.AttendanceRepository;
import  repository.ClassRepository;
import  repository.EnrollmentRepository;
import  repository.SessionRepository;
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

    private final SessionRepository sessionRepository;
    private final ClassRepository classRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final AttendanceRepository attendanceRepository;
    private final QrTokenService qrTokenService;

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

        // Tăng total_sessions
        cls.setTotalSessions(cls.getTotalSessions() + 1);

        String token = qrTokenService.generateForSession(s.getId());
        return toResponse(s, token, true);
    }

    @Transactional
    public SessionResponse refreshQr(Long sessionId, User teacher) {
        Session s = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));
        assertOwner(s, teacher);

        if (s.getStatus() != Session.Status.OPEN) {
            throw new ApiException(ErrorCode.SESSION_CLOSED);
        }

        String token = qrTokenService.generateForSession(s.getId());
        return toResponse(s, token, false);
    }

    @Transactional
    public SessionResponse close(Long sessionId, User teacher) {
        Session s = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));
        assertOwner(s, teacher);

        closeAndMarkAbsent(s);
        return toResponse(s, null, false);
    }

    /** Closes expired QR sessions and marks every roster student who did not
     * check in as absent. It is idempotent, so manual close and the scheduler
     * cannot create duplicate attendance rows. */
    @Scheduled(fixedDelayString = "${app.attendance.expiration-check-ms:15000}")
    @Transactional
    public void closeExpiredSessions() {
        sessionRepository.findByStatusAndQrExpiresAtLessThanEqual(
                        Session.Status.OPEN, Instant.now())
                .forEach(this::closeAndMarkAbsent);
    }

    @Transactional
    public void closeAndMarkAbsent(Session session) {
        if (session.getStatus() != Session.Status.OPEN) return;
        session.setStatus(Session.Status.CLOSED);
        session.setEndTime(Instant.now());
        enrollmentRepository.findByClassRoomId(session.getClassRoom().getId())
                .forEach(enrollment -> {
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
                .stream().map(s -> toResponse(s, null, false))
                .collect(Collectors.toList());
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
                //.className(s.getClassRoom().getClassName())
                .sessionDate(s.getSessionDate())
                .startTime(s.getStartTime())
                .endTime(s.getEndTime())
                .room(s.getRoom())
                .status(s.getStatus().name())
                .qrToken(qrToken)
                .qrExpiresAt(s.getQrExpiresAt());

        if (includeStats) {
            b.totalStudents(enrollmentRepository.countByClassRoomId(s.getClassRoom().getId()));
            b.checkedIn(attendanceRepository.countBySessionId(s.getId()));
        }
        return b.build();
    }
}
