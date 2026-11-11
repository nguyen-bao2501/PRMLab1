package service;

import dto.request.CreateSessionRequest;
import entity.*;
import exception.ApiException;
import org.junit.jupiter.api.Test;
import repository.*;
import java.time.Instant;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ScheduledLessonTest {
    private final SessionRepository sessions = mock(SessionRepository.class);
    private final ClassRepository classes = mock(ClassRepository.class);
    private final QrTokenService qr = mock(QrTokenService.class);
    private final User teacher = User.builder().id(1L).build();
    private final ClassRoom cls = ClassRoom.builder().id(2L).teacher(teacher).totalSessions(0).build();
    private final SessionService service = new SessionService(sessions, classes,
            mock(EnrollmentRepository.class), mock(AttendanceRepository.class), qr);

    @Test void schedulingDoesNotOpenAttendanceOrGenerateQr() {
        when(classes.findById(2L)).thenReturn(Optional.of(cls));
        Instant start = Instant.parse("2099-09-23T17:30:00Z");
        var result = service.schedule(new CreateSessionRequest(2L, "NVH 604", start), teacher);
        assertEquals("SCHEDULED", result.getStatus());
        assertEquals("2099-09-24", result.getSessionDate().toString());
        assertNull(result.getQrToken());
        assertNull(result.getQrExpiresAt());
        assertEquals(1, cls.getTotalSessions());
        verifyNoInteractions(qr);
    }

    @Test void openingChecksTimeOwnershipAndState() {
        Session lesson = Session.builder().id(3L).classRoom(cls)
                .startTime(Instant.now().plusSeconds(600)).status(Session.Status.SCHEDULED).build();
        when(sessions.findForOpening(3L)).thenReturn(Optional.of(lesson));
        assertThrows(ApiException.class, () -> service.open(3L, teacher));
        assertThrows(ApiException.class, () -> service.open(3L, User.builder().id(99L).build()));
        lesson.setStartTime(Instant.now().minusSeconds(136 * 60));
        assertThrows(ApiException.class, () -> service.open(3L, teacher));
        verifyNoInteractions(qr);
        lesson.setStartTime(Instant.now().minusSeconds(60));
        when(qr.getTtlSeconds()).thenReturn(600L);
        when(qr.generateForSession(3L)).thenReturn("token");
        assertEquals("OPEN", service.open(3L, teacher).getStatus());
        assertThrows(ApiException.class, () -> service.open(3L, teacher));
        verify(qr, times(1)).generateForSession(3L);
    }
    @Test void refusesOverlappingTeacherLessons() {
        when(classes.findById(2L)).thenReturn(Optional.of(cls));
        when(sessions.existsByClassRoomTeacherIdAndStatusNotAndStartTimeGreaterThanAndStartTimeLessThan(
                eq(1L), eq(Session.Status.CANCELLED), any(), any())).thenReturn(true);
        assertThrows(ApiException.class, () -> service.schedule(
                new CreateSessionRequest(2L, "NVH 604", Instant.now().plusSeconds(3600)), teacher));
        verify(sessions, never()).save(any());
        verifyNoInteractions(qr);
    }

}
