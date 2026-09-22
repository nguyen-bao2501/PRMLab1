package service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import controller.WebAttendanceController;
import entity.User;
import exception.ApiException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import repository.UserRepository;
import security.GoogleTokenVerifier;

import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class WebAttendanceTest {
    private final GoogleTokenVerifier verifier = mock(GoogleTokenVerifier.class);
    private final UserRepository users = mock(UserRepository.class);
    private final AttendanceService attendance = mock(AttendanceService.class);
    private final WebAttendanceController controller = new WebAttendanceController(verifier, users, attendance);

    private User prepare(boolean verified) {
        var payload = new GoogleIdToken.Payload();
        payload.setSubject("google-subject");
        payload.setEmail("STUDENT@example.org");
        payload.setEmailVerified(verified);
        when(verifier.verify("google-token")).thenReturn(payload);
        var user = User.builder().id(7L).email("student@example.org")
                .fullName("Student").studentCode("SE123456").isActive(true).build();
        when(users.findByEmail("student@example.org")).thenReturn(Optional.of(user));
        return user;
    }

    @Test void verifiedIdentityPopulatesFormWithoutRecordingAttendance() {
        prepare(true);
        var result = controller.identity(new WebAttendanceController.IdentityRequest("google-token"));
        assertEquals("SE123456", result.getData().get("studentCode"));
        assertEquals("student@example.org", result.getData().get("email"));
        verifyNoInteractions(attendance);
    }
    @Test void confirmationUsesVerifiedUserAndScannedToken() {
        var student = prepare(true);
        controller.checkIn(new WebAttendanceController.WebCheckIn("google-token", "qr-token"), new MockHttpServletRequest());
        verify(attendance).checkIn(argThat(req -> "qr-token".equals(req.getQrToken())), eq(student), anyString());
        verify(users, never()).save(any());
    }
    @Test void unverifiedEmailCannotIdentifyOrCheckIn() {
        prepare(false);
        assertThrows(ApiException.class, () -> controller.identity(new WebAttendanceController.IdentityRequest("google-token")));
        verifyNoInteractions(attendance);
    }
    @Test void unknownEmailCannotSelfRegisterThroughAttendanceForm() {
        prepare(true);
        when(users.findByEmail(anyString())).thenReturn(Optional.empty());
        assertThrows(ApiException.class, () -> controller.checkIn(
                new WebAttendanceController.WebCheckIn("google-token", "qr-token"), new MockHttpServletRequest()));
        verifyNoInteractions(attendance);
        verify(users, never()).save(any());
    }
    @Test void disabledAccountCannotCheckIn() {
        prepare(true).setIsActive(false);
        assertThrows(ApiException.class, () -> controller.identity(new WebAttendanceController.IdentityRequest("google-token")));
        verifyNoInteractions(attendance);
    }
}
