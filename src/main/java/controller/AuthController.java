package  controller;

import  dto.request.GoogleLoginRequest;
import  dto.response.ApiResponse;
import  dto.response.LoginResponse;
import  dto.response.UserResponse;
import  entity.User;
import  security.CurrentUser;
import  service.AuthService;
import  service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Auth", description = "Xác thực người dùng")
public class AuthController {

    private final AuthService authService;
    private final UserService userService;

    @PostMapping("/google")
    @Operation(summary = "Đăng nhập bằng Google id_token")
    public ApiResponse<LoginResponse> loginGoogle(@Valid @RequestBody GoogleLoginRequest req) {
        return ApiResponse.ok("Đăng nhập thành công",
                authService.loginWithGoogle(req.getIdToken()));
    }

    @GetMapping("/me")
    @Operation(summary = "Lấy thông tin user hiện tại")
    public ApiResponse<UserResponse> me(@CurrentUser User user) {
        return ApiResponse.ok(userService.getProfile(user));
    }
}
