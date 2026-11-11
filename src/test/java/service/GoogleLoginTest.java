package service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import entity.User;
import exception.ApiException;
import org.junit.jupiter.api.Test;
import repository.UserRepository;
import security.GoogleTokenVerifier;
import security.JwtProvider;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class GoogleLoginTest {
    private final GoogleTokenVerifier verifier = mock(GoogleTokenVerifier.class);
    private final UserRepository users = mock(UserRepository.class);
    private final JwtProvider jwt = mock(JwtProvider.class);
    private final AuthService auth = new AuthService(verifier, users, jwt);

    private void googleAccount(String email) {
        GoogleIdToken.Payload payload = new GoogleIdToken.Payload();
        payload.setSubject("google-subject");
        payload.setEmail(email);
        payload.setEmailVerified(true);
        payload.set("name", "Google User");
        when(verifier.verify("valid-id-token")).thenReturn(payload);
        when(users.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            if (user.getId() == null) user.setId(10L);
            return user;
        });
        when(jwt.generate(anyLong(), anyString(), anyString())).thenReturn("app-jwt");
    }

    @Test
    void newGoogleAccountGetsTeacherAccessWithoutDevRegistration() {
        googleAccount("NewTeacher@gmail.com");

        var response = auth.loginWithGoogle("valid-id-token");

        assertEquals("TEACHER", response.getUser().getRole());
        assertEquals("newteacher@gmail.com", response.getUser().getEmail());
        assertEquals("app-jwt", response.getAccessToken());
        verify(users).save(argThat(user ->
                user.getRole() == User.Role.TEACHER
                        && Boolean.TRUE.equals(user.getIsActive())
                        && "google-subject".equals(user.getGoogleId())));
        verify(jwt).generate(10L, "newteacher@gmail.com", "TEACHER");
    }

    @Test
    void existingStudentKeepsRoleWhenLinkingGoogle() {
        googleAccount("student@example.org");
        User student = User.builder().id(20L).email("student@example.org")
                .role(User.Role.STUDENT).isActive(true).build();
        when(users.findByEmail("student@example.org")).thenReturn(Optional.of(student));

        var response = auth.loginWithGoogle("valid-id-token");

        assertEquals("STUDENT", response.getUser().getRole());
        assertEquals("google-subject", student.getGoogleId());
        verify(jwt).generate(20L, "student@example.org", "STUDENT");
    }

    @Test
    void invalidGoogleTokenCannotCreateAccountOrIssueSession() {
        when(verifier.verify("invalid-token")).thenThrow(new IllegalArgumentException("Invalid token"));

        assertThrows(IllegalArgumentException.class, () -> auth.loginWithGoogle("invalid-token"));

        verifyNoInteractions(users, jwt);
    }

    @Test
    void cannotReplaceAnotherGoogleAccountLinkedToSameEmail() {
        googleAccount("teacher@gmail.com");
        User teacher = User.builder().id(30L).email("teacher@gmail.com")
                .googleId("other-subject").role(User.Role.TEACHER).isActive(true).build();
        when(users.findByEmail("teacher@gmail.com")).thenReturn(Optional.of(teacher));

        assertThrows(ApiException.class, () -> auth.loginWithGoogle("valid-id-token"));

        verify(users, never()).save(any());
        verifyNoInteractions(jwt);
    }
}
