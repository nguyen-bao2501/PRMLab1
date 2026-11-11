package controller;

import dto.request.CheckInRequest;
import dto.response.ApiResponse;
import dto.response.AttendanceResponse;
import entity.User;
import exception.ApiException;
import exception.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import repository.UserRepository;
import security.GoogleTokenVerifier;
import service.AttendanceService;

import java.util.Locale;
import java.util.Map;

@RestController
@RequestMapping("/v1/public/attendance")
@RequiredArgsConstructor
public class WebAttendanceController {
    private final GoogleTokenVerifier verifier;
    private final UserRepository users;
    private final AttendanceService attendance;

    @Value("${app.google.web-client-id:}")
    private String webClientId = "";

    @Value("${app.google.client-id:}")
    private String clientId = "";

    public record WebCheckIn(@NotBlank String idToken, @NotBlank String qrToken) {}
    public record IdentityRequest(@NotBlank String idToken) {}

    @PostMapping("/identity")
    public ApiResponse<Map<String, String>> identity(@Valid @RequestBody IdentityRequest request) {
        User student = identify(request.idToken());
        return ApiResponse.ok(Map.of("fullName", student.getFullName() == null ? "" : student.getFullName(),
                "email", student.getEmail(), "studentCode", student.getStudentCode() == null ? "" : student.getStudentCode()));
    }

    @GetMapping("/config")
    public ApiResponse<Map<String, String>> config() {
        String effectiveClientId = (webClientId != null && !webClientId.isBlank()) ? webClientId : clientId;
        return ApiResponse.ok(Map.of("clientId", effectiveClientId));
    }

    @PostMapping("/check-in")
    public ApiResponse<AttendanceResponse> checkIn(@Valid @RequestBody WebCheckIn request,
                                                  HttpServletRequest http) {
        User student = identify(request.idToken());
        return ApiResponse.ok("Điểm danh thành công", attendance.checkIn(
                new CheckInRequest(request.qrToken(), null, null, "Mobile Web"),
                student, http.getRemoteAddr()));
    }

    private User identify(String idToken) {
        var payload = verifier.verify(idToken);
        if (!Boolean.TRUE.equals(payload.getEmailVerified()) || payload.getEmail() == null) {
            throw new ApiException(ErrorCode.INVALID_GOOGLE_ACCOUNT);
        }
        // Email comes only from Google's verified token, never from a form.
        var student = users.findByEmail(payload.getEmail().trim().toLowerCase(Locale.ROOT))
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_IN_ROSTER,
                        "Email Google chưa có trong danh sách lớp. Liên hệ giảng viên."));
        if (!Boolean.TRUE.equals(student.getIsActive())) {
            throw new ApiException(ErrorCode.FORBIDDEN, "Tài khoản đã bị vô hiệu hóa.");
        }
        if (student.getGoogleId() != null && !student.getGoogleId().startsWith("pending_") && !student.getGoogleId().equals(payload.getSubject())) {
            throw new ApiException(ErrorCode.INVALID_GOOGLE_ACCOUNT, "Tài khoản Google không khớp với tài khoản đã liên kết.");
        }
        if (student.getGoogleId() == null || student.getGoogleId().startsWith("pending_")) {
            student.setGoogleId(payload.getSubject());
            users.save(student);
        }
        return student;
    }
}
