package controller;

import dto.request.CreateClassRequest;
import dto.request.ImportSheetRequest;
import dto.response.*;
import entity.User;
import security.CurrentUser;
import service.ClassService;
import service.GoogleSheetService;
import service.RosterSyncService;
import util.SheetNameParser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v1/classes")
@RequiredArgsConstructor
@Tag(name = "Classes", description = "Quản lý lớp học + Sheet")
public class ClassController {

    private final ClassService classService;
    private final RosterSyncService rosterSyncService;
    private final GoogleSheetService sheetService;

    // ==================== CRUD LỚP ====================

    @PostMapping
    @PreAuthorize("hasRole('TEACHER')")
    @Operation(summary = "Tạo lớp học mới")
    public ApiResponse<ClassResponse> create(@Valid @RequestBody CreateClassRequest req,
                                             @CurrentUser User teacher) {
        return ApiResponse.ok("Tạo lớp thành công", classService.create(req, teacher));
    }

    @GetMapping
    @PreAuthorize("hasRole('TEACHER')")
    public ApiResponse<List<ClassResponse>> list(@CurrentUser User teacher) {
        return ApiResponse.ok(classService.listByTeacher(teacher));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('TEACHER')")
    public ApiResponse<ClassResponse> getById(@PathVariable Long id,
                                              @CurrentUser User teacher) {
        return ApiResponse.ok(classService.getById(id, teacher));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('TEACHER')")
    public ApiResponse<Void> deactivate(@PathVariable Long id, @CurrentUser User teacher) {
        classService.deactivate(id, teacher);
        return ApiResponse.ok("Đã vô hiệu hóa lớp", null);
    }

    // ==================== SHEET TABS ====================

    /**
     * GET /v1/classes/sheet-tabs?spreadsheetId=xxx
     * Trả về danh sách tab đã parse sẵn subjectCode + classCode.
     * GV dùng để chọn tab khi import.
     */
    @GetMapping("/sheet-tabs")
    @PreAuthorize("hasRole('TEACHER')")
    @Operation(summary = "Lấy danh sách tab trong file Sheet (đã parse mã môn/mã lớp)")
    public ApiResponse<List<SheetTabResponse>> listSheetTabs(@RequestParam String spreadsheetId) {

        List<String> rawTabs = sheetService.listSheetTabs(spreadsheetId);

        List<SheetTabResponse> parsed = rawTabs.stream()
                .map(tab -> {
                    String[] p = SheetNameParser.parse(tab);
                    return SheetTabResponse.builder()
                            .sheetName(tab)
                            .subjectCode(p[0])
                            .classCode(p[1])
                            .build();
                })
                .collect(Collectors.toList());

        return ApiResponse.ok(parsed);
    }

    // ==================== IMPORT ====================

    /**
     * POST /v1/classes/{id}/import-sheet
     * Body: { "spreadsheetId": "...", "sheetName": "11_PRN232_SE1917" }
     */
    @PostMapping("/{id}/import-sheet")
    @PreAuthorize("hasRole('TEACHER')")
    @Operation(summary = "Import danh sách HS từ 1 tab Sheet vào DB")
    public ApiResponse<SheetImportResponse> importSheet(
            @PathVariable Long id,
            @Valid @RequestBody ImportSheetRequest req,
            @CurrentUser User teacher) {

        SheetImportResponse resp = rosterSyncService.importRoster(
                id, req.getSpreadsheetId(), req.getSheetName(), teacher);

        return ApiResponse.ok(
                String.format("Import '%s': %d thêm mới, %d bỏ qua",
                        req.getSheetName(),
                        resp.getRowsImported(), resp.getRowsSkipped()),
                resp);
    }
}