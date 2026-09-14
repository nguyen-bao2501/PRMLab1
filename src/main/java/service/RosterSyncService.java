package service;

import dto.SheetRosterRow;
import dto.response.SheetImportResponse;
import entity.*;
import exception.ApiException;
import exception.ErrorCode;
import repository.*;
import util.SheetNameParser;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class RosterSyncService {

    private final GoogleSheetService sheetService;
    private final UserRepository userRepository;
    private final ClassRepository classRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ClassSheetRepository classSheetRepository;
    private final SheetImportLogRepository logRepo;

    /**
     * Import roster từ 1 tab.
     *
     * @param classId       ID lớp trong DB (GV chọn)
     * @param spreadsheetId ID file Sheet
     * @param sheetName     Tên tab (VD: "11_PRN232_SE1917")
     * @param importer      GV
     */
    @Transactional
    public SheetImportResponse importRoster(Long classId,
                                            String spreadsheetId,
                                            String sheetName,
                                            User importer) {

        ClassRoom cls = classRepository.findById(classId)
                .orElseThrow(() -> new ApiException(ErrorCode.CLASS_NOT_FOUND));

        if (!cls.getTeacher().getId().equals(importer.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN);
        }

        // ⭐ Parse tên tab: "11_PRN232_SE1917" → subjectCode="PRN232", classCode="SE1917"
        String[] parsed = SheetNameParser.parse(sheetName);
        String subjectCode = parsed[0];
        String classCodeFromTab = parsed[1];

        log.info("Import tab '{}': subjectCode={}, classCodeFromTab={}",
                sheetName, subjectCode, classCodeFromTab);

        // Cập nhật subjectCode cho class nếu chưa có
        if (cls.getSubjectCode() == null && subjectCode != null) {
            cls.setSubjectCode(subjectCode);
            classRepository.save(cls);
        }

        // Lưu mapping lớp ↔ sheet
        ClassSheet classSheet = classSheetRepository.findByClassRoomId(classId)
                .orElseGet(() -> ClassSheet.builder().classRoom(cls).build());

        classSheet.setSpreadsheetId(spreadsheetId);
        classSheet.setSheetName(sheetName);
        classSheet.setSubjectCode(subjectCode);
        classSheet.setLastSyncedAt(Instant.now());
        classSheetRepository.save(classSheet);

        // Đọc tab
        List<SheetRosterRow> rows;
        try {
            rows = sheetService.importRoster(spreadsheetId, sheetName);
        } catch (ApiException e) {
            logRepo.save(SheetImportLog.builder()
                    .classId(classId)
                    .spreadsheetId(spreadsheetId)
                    .sheetName(sheetName)
                    .subjectCode(subjectCode)
                    .importedBy(importer.getId())
                    .status("FAILED")
                    .message(e.getMessage())
                    .build());
            throw e;
        }

        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.SHEET_ERROR,
                    "Tab '" + sheetName + "' rỗng hoặc không có dòng hợp lệ");
        }

        // Xử lý từng dòng
        int imported = 0, skipped = 0;

        for (SheetRosterRow row : rows) {
            // Ưu tiên match theo MSSV trước, fallback email
            User student = null;
            if (row.getRollNumber() != null && !row.getRollNumber().isBlank()) {
                student = userRepository.findByStudentCode(row.getRollNumber()).orElse(null);
            }
            if (student == null) {
                student = userRepository.findByEmail(row.getEmail()).orElse(null);
            }
            if (student == null) {
                student = userRepository.save(User.builder()
                        .email(row.getEmail())
                        .fullName(row.getFullName())
                        .studentCode(row.getRollNumber())
                        .role(User.Role.STUDENT)
                        .isActive(true)
                        .build());
            } else {
                boolean needUpdate = false;
                if (student.getStudentCode() == null && row.getRollNumber() != null) {
                    student.setStudentCode(row.getRollNumber());
                    needUpdate = true;
                }
                if (student.getFullName() == null && row.getFullName() != null) {
                    student.setFullName(row.getFullName());
                    needUpdate = true;
                }
                if (needUpdate) userRepository.save(student);
            }

            // Enroll
            if (enrollmentRepository.existsByClassRoomIdAndStudentId(classId, student.getId())) {
                skipped++;
                continue;
            }
            enrollmentRepository.save(Enrollment.builder()
                    .classRoom(cls).student(student).build());
            imported++;
        }

        // Đảm bảo cột F có header
        sheetService.ensureAttendanceHeader(spreadsheetId, sheetName);

        // Log
        logRepo.save(SheetImportLog.builder()
                .classId(classId)
                .spreadsheetId(spreadsheetId)
                .sheetName(sheetName)
                .subjectCode(subjectCode)
                .rowsImported(imported)
                .rowsSkipped(skipped)
                .importedBy(importer.getId())
                .status("SUCCESS")
                .message("Import tab '" + sheetName + "' thành công")
                .build());

        log.info("Import tab={} class={}: imported={}, skipped={}",
                sheetName, classId, imported, skipped);

        return SheetImportResponse.builder()
                .classId(classId)
                .spreadsheetId(spreadsheetId)
                .sheetName(sheetName)
                .subjectCode(subjectCode)
                .classCodeFromTab(classCodeFromTab)
                .rowsImported(imported)
                .rowsSkipped(skipped)
                .totalInSheet(rows.size())
                .build();
    }
}