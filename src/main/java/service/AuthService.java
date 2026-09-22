package service;

import dto.response.LoginResponse;
import dto.response.UserResponse;
import entity.User;
import exception.ApiException;
import exception.ErrorCode;
import repository.UserRepository;
import security.GoogleTokenVerifier;
import security.JwtProvider;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final GoogleTokenVerifier verifier;
    private final UserRepository userRepository;
    private final JwtProvider jwtProvider;

    @Transactional
    public LoginResponse loginWithGoogle(String idToken) {
        GoogleIdToken.Payload payload = verifier.verify(idToken);

        String googleId = payload.getSubject();
        String email = payload.getEmail();
        if (email == null || email.isBlank()) {
            throw new ApiException(ErrorCode.INVALID_GOOGLE_ACCOUNT,
                    "Google không trả về địa chỉ email cho tài khoản này");
        }
        final String normalizedEmail = email.trim().toLowerCase(Locale.ROOT);
        String name = (String) payload.get("name");
        String picture = (String) payload.get("picture");

        // 1. Tìm theo googleId trước
        Optional<User> existing = userRepository.findByGoogleId(googleId);

        // 2. Nếu không có, tìm theo email (đã được import từ Sheet)
        if (existing.isEmpty()) {
            existing = userRepository.findByEmail(normalizedEmail);
        }

        User user = existing.map(u -> {
            // Một Google subject chỉ được phép map với đúng email đã xác thực.
            // Không cho phép đổi email của user đã có bằng dữ liệu từ client.
            if (!normalizedEmail.equals(u.getEmail())) {
                throw new ApiException(ErrorCode.INVALID_GOOGLE_ACCOUNT,
                        "Email của tài khoản Google không khớp với tài khoản đã liên kết");
            }
            if (u.getGoogleId() != null && !googleId.equals(u.getGoogleId())) {
                throw new ApiException(ErrorCode.INVALID_GOOGLE_ACCOUNT,
                        "Email này đã liên kết với một tài khoản Google khác");
            }
            // Cập nhật googleId + avatar nếu chưa có
            if (u.getGoogleId() == null) u.setGoogleId(googleId);
            if (picture != null) u.setAvatarUrl(picture);
            if (name != null) u.setFullName(name);
            return userRepository.save(u);
        }).orElseGet(() -> {
            // Tạo user mới (chưa có trong hệ thống)
            log.info("Tạo user mới: {} - {}", normalizedEmail, name);
            // Ứng dụng giảng viên cho phép tự đăng ký bằng Google,
            // không cần tạo email qua dev login trước.
            return userRepository.save(User.builder()
                    .googleId(googleId)
                    .email(normalizedEmail)
                    .fullName(name)
                    .avatarUrl(picture)
                    .role(User.Role.TEACHER)
                    .isActive(true)
                    .build());
        });

        String token = jwtProvider.generate(user.getId(), user.getEmail(), user.getRole().name());

        return LoginResponse.builder()
                .accessToken(token)
                .tokenType("Bearer")
                .expiresIn(jwtProvider.getExpirationMs() / 1000)
                .user(UserResponse.builder()
                        .id(user.getId())
                        .email(user.getEmail())
                        .fullName(user.getFullName())
                        .avatarUrl(user.getAvatarUrl())
                        .studentCode(user.getStudentCode())
                        .role(user.getRole().name())
                        .build())
                .build();
    }
}
