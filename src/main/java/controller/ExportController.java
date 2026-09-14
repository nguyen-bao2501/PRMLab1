package controller;

import dto.response.ApiResponse;
import dto.response.ExportResponse;
import entity.*;
import exception.ApiException;
import exception.ErrorCode;
import repository.*;
import security.CurrentUser;
import service.GoogleSheetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/exports")
@RequiredArgsConstructor
@Tag(name = "Exports", description = "Xuất điểm danh ra Google Sheet")
public class ExportController {

    private final GoogleSheetService sheetService;
    private final SessionRepository sessionRepository;
    private final ClassSheetRepository classSheetRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final AttendanceRepository attendanceRepository;


    @PostMapping("/session/{sessionId}")
    @PreAuthorize("hasRole('TEACHER')")
    @Operation(summary = "Xuất điểm danh vào cột F của tab đã cấu hình")
    public ApiResponse<ExportResponse> exportSession(
            @PathVariable Long sessionId,
            @CurrentUser User teacher) {

        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.SESSION_NOT_FOUND));

        if (!session.getClassRoom().getTeacher().getId().equals(teacher.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN);
        }

        ClassSheet classSheet = classSheetRepository
                .findByClassRoomId(session.getClassRoom().getId())
                .orElseThrow(() -> new ApiException(ErrorCode.SHEET_NOT_CONFIGURED,
                        "Lớp chưa import Sheet, vui lòng import trước"));

        String sheetName = classSheet.getSheetName();

        // 1. Lấy HS trong lớp
        List<Enrollment> enrollments = enrollmentRepository
                .findByClassRoomId(session.getClassRoom().getId());

        // 2. Lấy attendance của session
        List<Attendance> attendances = attendanceRepository.findBySessionId(sessionId);
        Map<Long, String> studentMark = new HashMap<>();
        for (Attendance a : attendances) {
            studentMark.put(a.getStudent().getId(),
                    a.getMarkCode() != null ? a.getMarkCode() : "A");
        }

        // 3. Build email → mark
        Map<String, String> emailToMark = new HashMap<>();
        long present = 0, absent = 0;
        for (Enrollment e : enrollments) {
            String email = e.getStudent().getEmail().toLowerCase();
            String mark = studentMark.getOrDefault(e.getStudent().getId(), "AS");
            emailToMark.put(email, mark);
            if ("A".equals(mark)) present++;
            else absent++;
        }

        // 4. Đảm bảo header cột F
        sheetService.ensureAttendanceHeader(classSheet.getSpreadsheetId(), sheetName);

        // 5. Ghi cột F
        sheetService.writeAttendanceColumn(
                classSheet.getSpreadsheetId(),
                sheetName,
                emailToMark
        );

        // 6. Share cho GV
        sheetService.shareSheet(classSheet.getSpreadsheetId(), teacher.getEmail());

        String url = "https://docs.google.com/spreadsheets/d/"
                + classSheet.getSpreadsheetId() + "/edit";

        return ApiResponse.ok("Xuất điểm danh thành công", ExportResponse.builder()
                .sessionId(sessionId)
                .spreadsheetId(classSheet.getSpreadsheetId())
                .sheetName(sheetName)
                .spreadsheetUrl(url)
                .presentCount(present)
                .absentCount(absent)
                .totalStudents(enrollments.size())
                .build());
    }
}