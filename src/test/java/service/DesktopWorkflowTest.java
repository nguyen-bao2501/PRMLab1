package service;

import dto.response.SessionResponse;
import entity.ClassRoom;
import entity.Session;
import entity.User;
import org.junit.jupiter.api.Test;
import repository.*;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class DesktopWorkflowTest {
    @Test
    void deletedClassesAreNotReturnedToDesktop() {
        ClassRepository classes = mock(ClassRepository.class);
        EnrollmentRepository enrollments = mock(EnrollmentRepository.class);
        ClassSheetRepository sheets = mock(ClassSheetRepository.class);
        User teacher = User.builder().id(1L).build();
        ClassRoom active = ClassRoom.builder().id(10L).isActive(true).build();
        ClassRoom deleted = ClassRoom.builder().id(11L).isActive(false).build();
        when(classes.findByTeacherIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(active, deleted));
        when(sheets.findByClassRoomId(10L)).thenReturn(Optional.empty());
        var results = new ClassService(classes, enrollments, sheets).listByTeacher(teacher);
        assertEquals(1, results.size());
        assertEquals(10L, results.get(0).getId());
        verify(sheets, never()).findByClassRoomId(11L);
    }

    @Test
    void refreshingQrExtendsThePersistedExpiryUsedByTheSchedulerAndDesktop() {
        SessionRepository sessions = mock(SessionRepository.class);
        QrTokenService qr = mock(QrTokenService.class);
        User teacher = User.builder().id(1L).build();
        ClassRoom classroom = ClassRoom.builder().id(10L).teacher(teacher).classCode("SE1917").build();
        Instant oldExpiry = Instant.now().plusSeconds(5);
        Session session = Session.builder().id(9L).classRoom(classroom).status(Session.Status.OPEN).qrExpiresAt(oldExpiry).build();
        when(sessions.findById(9L)).thenReturn(Optional.of(session));
        when(qr.getTtlSeconds()).thenReturn(600L);
        when(qr.generateForSession(9L)).thenReturn("new-token");
        var service = new SessionService(sessions, mock(ClassRepository.class), mock(EnrollmentRepository.class), mock(AttendanceRepository.class), qr);
        org.springframework.test.util.ReflectionTestUtils.setField(service, "publicBaseUrl", "https://attendance.example/");
        Instant before = Instant.now();
        SessionResponse result = service.refreshQr(9L, teacher);
        assertEquals("new-token", result.getQrToken());
        assertEquals("https://attendance.example/check-in.html#token=new-token", result.getQrUrl());
        assertEquals(session.getQrExpiresAt(), result.getQrExpiresAt());
        assertTrue(result.getQrExpiresAt().isAfter(oldExpiry));
        assertFalse(result.getQrExpiresAt().isBefore(before.plusSeconds(600)));
    }
}
