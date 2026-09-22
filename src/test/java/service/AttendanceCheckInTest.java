package service;

import dto.request.CheckInRequest;
import entity.Attendance;
import entity.ClassRoom;
import entity.Session;
import entity.User;
import exception.ApiException;
import exception.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import repository.AttendanceRepository;
import repository.EnrollmentRepository;
import repository.SessionRepository;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AttendanceCheckInTest {
    private final AttendanceRepository rows = mock(AttendanceRepository.class);
    private final SessionRepository sessions = mock(SessionRepository.class);
    private final EnrollmentRepository roster = mock(EnrollmentRepository.class);
    private final QrTokenService qr = mock(QrTokenService.class);
    private final AttendanceService service = new AttendanceService(
            rows, sessions, roster, qr, mock(SessionService.class));
    private final User student = User.builder().id(5L).email("student@example.org")
            .role(User.Role.STUDENT).fullName("Student").build();
    private final Session session = Session.builder().id(8L)
            .classRoom(ClassRoom.builder().id(3L).build())
            .status(Session.Status.OPEN).qrExpiresAt(Instant.now().plusSeconds(120)).build();
    private final CheckInRequest request = new CheckInRequest("valid-qr", null, null, "Phone");

    @BeforeEach
    void prepare() {
        when(qr.resolveSessionId("valid-qr")).thenReturn(8L);
        when(sessions.findById(8L)).thenReturn(Optional.of(session));
        when(roster.existsByClassRoomIdAndStudentId(3L, 5L)).thenReturn(true);
        when(rows.save(any())).thenAnswer(call -> {
            Attendance row = call.getArgument(0);
            row.setId(10L);
            row.setCheckInTime(Instant.now());
            return row;
        });
    }

    @Test
    void validQrRecordsAttendanceForEnrolledStudent() {
        var result = service.checkIn(request, student, "192.168.1.2");
        assertEquals("PRESENT", result.getStatus());
        assertEquals(5L, result.getStudentId());
        assertEquals(8L, result.getSessionId());
        verify(rows).save(argThat(row -> "Phone".equals(row.getDeviceInfo())));
    }

    private void rejects(ErrorCode code) {
        var error = assertThrows(ApiException.class,
                () -> service.checkIn(request, student, "192.168.1.2"));
        assertEquals(code, error.getErrorCode());
        verify(rows, never()).save(any());
    }

    @Test void unknownQrIsRejected() {
        when(qr.resolveSessionId("valid-qr")).thenReturn(null);
        rejects(ErrorCode.QR_EXPIRED);
    }
    @Test void expiredSessionIsRejected() {
        session.setQrExpiresAt(Instant.now().minusSeconds(1));
        rejects(ErrorCode.QR_EXPIRED);
    }
    @Test void closedSessionIsRejected() {
        session.setStatus(Session.Status.CLOSED);
        rejects(ErrorCode.SESSION_CLOSED);
    }
    @Test void studentOutsideRosterIsRejected() {
        when(roster.existsByClassRoomIdAndStudentId(3L, 5L)).thenReturn(false);
        rejects(ErrorCode.NOT_IN_ROSTER);
    }
    @Test void duplicateCheckInIsRejected() {
        when(rows.existsBySessionIdAndStudentId(8L, 5L)).thenReturn(true);
        rejects(ErrorCode.ALREADY_CHECKED_IN);
    }
}
