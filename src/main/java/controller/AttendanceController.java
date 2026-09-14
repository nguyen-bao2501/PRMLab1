package  controller;

import  dto.request.CheckInRequest;
import  dto.response.ApiResponse;
import  dto.response.AttendanceResponse;
import  entity.User;
import  security.CurrentUser;
import  service.AttendanceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/attendances")
@RequiredArgsConstructor
@Tag(name = "Attendances", description = "Điểm danh")
public class AttendanceController {

    private final AttendanceService attendanceService;

    @PostMapping("/check-in")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "HS quét QR và điểm danh")
    public ApiResponse<AttendanceResponse> checkIn(
            @Valid @RequestBody CheckInRequest req,
            @CurrentUser User student,
            HttpServletRequest http) {
        String ip = extractIp(http);
        return ApiResponse.ok("Điểm danh thành công",
                attendanceService.checkIn(req, student, ip));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('TEACHER','ADMIN')")
    @Operation(summary = "GV xem danh sách đã điểm danh")
    public ApiResponse<List<AttendanceResponse>> listBySession(
            @RequestParam Long sessionId,
            @CurrentUser User teacher) {
        return ApiResponse.ok(attendanceService.listBySession(sessionId, teacher));
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "HS xem lịch sử điểm danh của mình")
    public ApiResponse<List<AttendanceResponse>> myHistory(@CurrentUser User student) {
        return ApiResponse.ok(attendanceService.listByStudent(student));
    }

    private String extractIp(HttpServletRequest req) {
        String xff = req.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) return xff.split(",")[0].trim();
        return req.getRemoteAddr();
    }
}