package service;

import dto.SheetRosterRow;
import exception.ApiException;
import exception.ErrorCode;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.sheets.v4.Sheets;
import com.google.api.services.sheets.v4.model.*;
import com.google.auth.http.HttpCredentialsAdapter;
import com.google.auth.oauth2.GoogleCredentials;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.*;

@Service
@Slf4j
public class GoogleSheetService {

    private static final List<String> SCOPES = List.of(
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive"
    );

    // ⭐ Cố định format cột
    private static final String COL_EMAIL  = "C";   // Email
    private static final String COL_ATTEND = "F";   // Điểm danh

    private final String serviceAccountPath;
    private final ResourceLoader resourceLoader;
    private Sheets cachedClient;

    public GoogleSheetService(
            @Value("${app.google.service-account-path}") String path,
            ResourceLoader resourceLoader) {
        this.serviceAccountPath = path;
        this.resourceLoader = resourceLoader;
    }

    private synchronized Sheets getClient() {
        if (cachedClient != null) return cachedClient;
        try {
            InputStream is = resourceLoader.getResource(serviceAccountPath).getInputStream();
            GoogleCredentials creds = GoogleCredentials.fromStream(is).createScoped(SCOPES);
            cachedClient = new Sheets.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(),
                    GsonFactory.getDefaultInstance(),
                    new HttpCredentialsAdapter(creds))
                    .setApplicationName("attendance-service")
                    .build();
            return cachedClient;
        } catch (Exception e) {
            throw new ApiException(ErrorCode.SHEET_ERROR,
                    "Không khởi tạo được Sheets client: " + e.getMessage());
        }
    }

    // ==================== LIST SHEET TABS ====================

    
    public List<String> listSheetTabs(String spreadsheetId) {
        try {
            Sheets sheets = getClient();
            Spreadsheet spreadsheet = sheets.spreadsheets().get(spreadsheetId).execute();

            List<String> tabs = new ArrayList<>();
            for (Sheet s : spreadsheet.getSheets()) {
                tabs.add(s.getProperties().getTitle());
            }
            log.info("Tìm thấy {} tab trong sheet {}", tabs.size(), spreadsheetId);
            return tabs;
        } catch (Exception e) {
            throw new ApiException(ErrorCode.SHEET_ERROR,
                    "Không lấy được danh sách tab: " + e.getMessage());
        }
    }

    // ==================== IMPORT ROSTER ====================

    
    public List<SheetRosterRow> importRoster(String spreadsheetId, String sheetName) {
        try {
            Sheets sheets = getClient();
            String range = sheetName + "!A2:E";

            ValueRange resp = sheets.spreadsheets().values()
                    .get(spreadsheetId, range)
                    .execute();

            List<List<Object>> rows = resp.getValues();
            if (rows == null || rows.isEmpty()) {
                log.warn("Tab '{}' rỗng", sheetName);
                return List.of();
            }

            List<SheetRosterRow> result = new ArrayList<>();
            int rowNum = 2;
            for (List<Object> row : rows) {
                String email = get(row, 2);   // cột C
                if (email == null || email.isBlank()) {
                    rowNum++;
                    continue;
                }
                result.add(SheetRosterRow.builder()
                        .rowIndex(rowNum)
                        .classCode(get(row, 0))                    // A
                        .rollNumber(get(row, 1))                   // B
                        .email(email.trim().toLowerCase())         // C
                        .memberCode(get(row, 3))                   // D
                        .fullName(get(row, 4))                     // E
                        .build());
                rowNum++;
            }
            log.info("Đọc {} dòng từ tab '{}'", result.size(), sheetName);
            return result;
        } catch (Exception e) {
            log.error("Import roster failed", e);
            throw new ApiException(ErrorCode.SHEET_ERROR,
                    "Không đọc được tab '" + sheetName + "': " + e.getMessage());
        }
    }

    private String get(List<Object> row, int idx) {
        if (idx >= row.size()) return null;
        Object v = row.get(idx);
        return v == null ? null : String.valueOf(v);
    }

    // ==================== WRITE ATTENDANCE ====================
    
    public void writeAttendanceColumn(String spreadsheetId,
                                      String sheetName,
                                      Map<String, String> emailToMark) {
        try {
            Sheets sheets = getClient();

            String readRange = sheetName + "!" + COL_EMAIL + "2:" + COL_EMAIL;
            ValueRange resp = sheets.spreadsheets().values()
                    .get(spreadsheetId, readRange)
                    .execute();
            List<List<Object>> emails = resp.getValues();
            if (emails == null || emails.isEmpty()) {
                throw new ApiException(ErrorCode.SHEET_ERROR,
                        "Tab '" + sheetName + "' không có dữ liệu email");
            }

            List<List<Object>> marks = new ArrayList<>();
            int present = 0, absent = 0;
            for (List<Object> row : emails) {
                String email = row.isEmpty() ? ""
                        : String.valueOf(row.get(0)).trim().toLowerCase();
                String mark = emailToMark.getOrDefault(email, "AS");
                marks.add(List.of(mark));
                if ("A".equals(mark)) present++;
                else absent++;
            }

            ValueRange body = new ValueRange().setValues(marks);
            sheets.spreadsheets().values()
                    .update(spreadsheetId,
                            sheetName + "!" + COL_ATTEND + "2:" + COL_ATTEND,
                            body)
                    .setValueInputOption("RAW")
                    .execute();

            log.info("Ghi tab '{}': {} có mặt, {} vắng",
                    sheetName, present, absent);
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            throw new ApiException(ErrorCode.SHEET_ERROR,
                    "Không ghi được tab '" + sheetName + "': " + e.getMessage());
        }
    }

    // ==================== HEADER ====================

    public void ensureAttendanceHeader(String spreadsheetId, String sheetName) {
        try {
            Sheets sheets = getClient();
            String cell = sheetName + "!" + COL_ATTEND + "1";

            ValueRange resp = sheets.spreadsheets().values()
                    .get(spreadsheetId, cell).execute();

            boolean hasHeader = resp.getValues() != null
                    && !resp.getValues().isEmpty()
                    && resp.getValues().get(0) != null
                    && !resp.getValues().get(0).isEmpty()
                    && resp.getValues().get(0).get(0) != null
                    && !String.valueOf(resp.getValues().get(0).get(0)).isBlank();

            if (!hasHeader) {
                ValueRange body = new ValueRange()
                        .setValues(List.of(List.of("Điểm danh")));
                sheets.spreadsheets().values()
                        .update(spreadsheetId, cell, body)
                        .setValueInputOption("RAW")
                        .execute();
                log.info("Đã thêm header 'Điểm danh' vào cột {}", COL_ATTEND);
            }
        } catch (Exception e) {
            log.warn("Không thể kiểm tra/ghi header: {}", e.getMessage());
        }
    }

    // ==================== SHARE ====================

    public void shareSheet(String spreadsheetId, String email) {
        try {
            var drive = new com.google.api.services.drive.Drive.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(),
                    GsonFactory.getDefaultInstance(),
                    new HttpCredentialsAdapter(
                            GoogleCredentials.fromStream(
                                    resourceLoader.getResource(serviceAccountPath).getInputStream()
                            ).createScoped(List.of("https://www.googleapis.com/auth/drive"))
                    ))
                    .setApplicationName("attendance-service")
                    .build();

            var perm = new com.google.api.services.drive.model.Permission()
                    .setType("user").setRole("writer").setEmailAddress(email);

            drive.permissions().create(spreadsheetId, perm)
                    .setSendNotificationEmail(false)
                    .execute();
        } catch (Exception e) {
            log.warn("Share sheet failed: {}", e.getMessage());
        }
    }
}