package  controller;

import  dto.request.CreateSessionRequest;
import  dto.response.ApiResponse;
import  dto.response.SessionResponse;
import  entity.User;
import  security.CurrentUser;
import  service.SessionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/sessions")
@RequiredArgsConstructor
@Tag(name = "Sessions", description = "Buổi điểm danh + QR")
public class SessionController {

    private final SessionService sessionService;

    @PostMapping
    @PreAuthorize("hasRole('TEACHER')")
    @Operation(summary = "Tạo buổi điểm danh + QR đầu tiên")
    public ApiResponse<SessionResponse> create(@Valid @RequestBody CreateSessionRequest req,
                                               @CurrentUser User teacher) {
        return ApiResponse.ok("Tạo buổi điểm danh thành công",
                sessionService.create(req, teacher));
    }

    @PostMapping("/{id}/refresh-qr")
    @PreAuthorize("hasRole('TEACHER')")
    @Operation(summary = "Refresh QR (Desktop gọi mỗi 25-30s)")
    public ApiResponse<SessionResponse> refreshQr(@PathVariable Long id,
                                                  @CurrentUser User teacher) {
        return ApiResponse.ok(sessionService.refreshQr(id, teacher));
    }

    @PostMapping("/{id}/close")
    @PreAuthorize("hasRole('TEACHER')")
    @Operation(summary = "Kết thúc buổi điểm danh")
    public ApiResponse<SessionResponse> close(@PathVariable Long id,
                                              @CurrentUser User teacher) {
        return ApiResponse.ok("Đã kết thúc buổi", sessionService.close(id, teacher));
    }

    @GetMapping
    @PreAuthorize("hasRole('TEACHER')")
    @Operation(summary = "Danh sách buổi của lớp")
    public ApiResponse<List<SessionResponse>> list(@RequestParam Long classId,
                                                   @CurrentUser User teacher) {
        return ApiResponse.ok(sessionService.listByClass(classId, teacher));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('TEACHER')")
    public ApiResponse<SessionResponse> getById(@PathVariable Long id,
                                                @CurrentUser User teacher) {
        return ApiResponse.ok(sessionService.getById(id, teacher));
    }
}