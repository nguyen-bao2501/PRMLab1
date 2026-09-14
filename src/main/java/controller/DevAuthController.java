package controller;

import dto.request.DevLoginRequest;
import dto.response.ApiResponse;
import dto.response.LoginResponse;
import dto.response.UserResponse;
import entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import repository.UserRepository;
import security.JwtProvider;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1/dev")
@RequiredArgsConstructor
@Slf4j
@Profile("dev")
@Tag(name = "Dev Auth", description = "Login nhanh không cần Google (chỉ dùng cho dev)")
public class DevAuthController {

    private final UserRepository userRepository;
    private final JwtProvider jwtProvider;

    @PostMapping("/login")
    @Operation(summary = "Dev login - không cần Google OAuth")
    public ApiResponse<LoginResponse> devLogin(@RequestBody DevLoginRequest req) {

        String email = req.getEmail() == null || req.getEmail().isBlank()
                ? "devtest@gmail.com"
                : req.getEmail().trim().toLowerCase();

        User.Role role;
        try {
            role = User.Role.valueOf(
                    (req.getRole() == null || req.getRole().isBlank())
                            ? "TEACHER"
                            : req.getRole().toUpperCase()
            );
        } catch (IllegalArgumentException e) {
            role = User.Role.TEACHER;
        }

        // Tìm hoặc tạo user
        final String finalEmail = email;
        final User.Role finalRole = role;

        User user = userRepository.findByEmail(finalEmail)
                .orElseGet(() -> {
                    log.info("Dev login: tạo user mới {}", finalEmail);
                    return userRepository.save(User.builder()
                            .email(finalEmail)
                            .fullName("Dev " + finalRole.name())
                            .role(finalRole)
                            .isActive(true)
                            .build());
                });

        // Cập nhật role nếu khác
        if (user.getRole() != finalRole) {
            user.setRole(finalRole);
            userRepository.save(user);
        }

        // Generate JWT
        String token = jwtProvider.generate(
                user.getId(),
                user.getEmail(),
                user.getRole().name()
        );

        log.info("Dev login OK: {} ({})", user.getEmail(), user.getRole());

        return ApiResponse.ok("Dev login thành công", LoginResponse.builder()
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
                .build());
    }

}