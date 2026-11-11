package service;

import dto.SheetRosterRow;
import exception.ApiException;
import exception.ErrorCode;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.googleapis.json.GoogleJsonResponseException;
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
            var resource = resourceLoader.getResource(serviceAccountPath);
            if (!resource.exists()) {
                log.warn("Service account file not found at {}. Google Sheets API will use public HTTP fallback.", serviceAccountPath);
                return null;
            }
            InputStream is = resource.getInputStream();
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
                    extractGoogleApiError(e, "Không khởi tạo được Sheets client"));
        }
    }

    private String extractGoogleApiError(Exception e, String defaultMessage) {
        if (e instanceof GoogleJsonResponseException) {
            GoogleJsonResponseException ge = (GoogleJsonResponseException) e;
            if (ge.getStatusCode() == 403) {
                return "Hệ thống chưa được cấp quyền truy cập. Vui lòng thêm email hệ thống vào danh sách 'Người chỉnh sửa' (Editor) của file Google Sheet này.";
            } else if (ge.getStatusCode() == 404) {
                return "Không tìm thấy file Google Sheet. Vui lòng kiểm tra lại đường link hoặc ID.";
            }
            if (ge.getDetails() != null && ge.getDetails().getMessage() != null) {
                return defaultMessage + " (" + ge.getDetails().getMessage() + ")";
            }
        }
        return defaultMessage + " (" + e.getMessage() + ")";
    }

    // ==================== LIST SHEET TABS ====================

    public List<String> listSheetTabs(String spreadsheetId) {
        try {
            Sheets sheets = getClient();
            if (sheets != null) {
                Spreadsheet spreadsheet = sheets.spreadsheets().get(spreadsheetId).execute();
                List<String> tabs = new ArrayList<>();
                for (Sheet s : spreadsheet.getSheets()) {
                    tabs.add(s.getProperties().getTitle());
                }
                log.info("Tìm thấy {} tab từ Google Sheets API", tabs.size());
                return tabs;
            }
        } catch (Exception e) {
            log.warn("Sheets API error, falling back to public HTTP fetch: {}", e.getMessage());
        }

        // Public HTTP fallback: Lấy tab động từ htmlview
        return fetchTabsPublic(spreadsheetId);
    }

    private List<String> fetchTabsPublic(String spreadsheetId) {
        try {
            String urlStr = "https://docs.google.com/spreadsheets/d/" + spreadsheetId + "/htmlview";
            java.net.URL url = new java.net.URI(urlStr).toURL();
            java.net.HttpURLConnection conn = (java.net.HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");

            try (java.io.BufferedReader reader = new java.io.BufferedReader(
                    new java.io.InputStreamReader(conn.getInputStream(), java.nio.charset.StandardCharsets.UTF_8))) {
                StringBuilder html = new StringBuilder();
                String l;
                while ((l = reader.readLine()) != null) {
                    html.append(l).append("\n");
                }
                List<String> tabs = new ArrayList<>();
                java.util.regex.Matcher matcher = java.util.regex.Pattern
                        .compile("name:\\s*\"([^\"]+)\"")
                        .matcher(html.toString());
                while (matcher.find()) {
                    String tabName = matcher.group(1).trim();
                    if (!tabs.contains(tabName)) {
                        tabs.add(tabName);
                    }
                }
                if (!tabs.isEmpty()) {
                    log.info("Đọc động thành công {} tab từ public Google Sheet URL", tabs.size());
                    return tabs;
                }
            }
        } catch (Exception e) {
            throw new ApiException(ErrorCode.SHEET_ERROR,
                    extractGoogleApiError(e, "Không lấy được danh sách tab"));
        }
        throw new ApiException(ErrorCode.SHEET_ERROR, "Không đọc được danh sách tab từ Google Sheet. Hãy kiểm tra lại link hoặc quyền truy cập của file.");
    }

    // ==================== IMPORT ROSTER ====================

    public List<SheetRosterRow> importRoster(String spreadsheetId, String sheetName) {
        try {
            Sheets sheets = getClient();
            if (sheets != null) {
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
            }
        } catch (Exception e) {
            log.warn("Sheets API import failed, trying public CSV import: {}", e.getMessage());
        }

        // Public HTTP fallback: Đọc CSV trực tiếp từ Google Sheet public
        return importRosterPublic(spreadsheetId, sheetName);
    }

    private List<SheetRosterRow> importRosterPublic(String spreadsheetId, String sheetName) {
        try {
            String encodedSheet = java.net.URLEncoder.encode(sheetName, java.nio.charset.StandardCharsets.UTF_8);
            String urlStr = "https://docs.google.com/spreadsheets/d/" + spreadsheetId + "/gviz/tq?tqx=out:csv&sheet=" + encodedSheet;
            java.net.URL url = new java.net.URI(urlStr).toURL();
            java.net.HttpURLConnection conn = (java.net.HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("User-Agent", "Mozilla/5.0");

            List<SheetRosterRow> result = new ArrayList<>();
            try (java.io.BufferedReader reader = new java.io.BufferedReader(
                    new java.io.InputStreamReader(conn.getInputStream(), java.nio.charset.StandardCharsets.UTF_8))) {
                String line;
                int rowNum = 1;
                while ((line = reader.readLine()) != null) {
                    if (rowNum == 1) {
                        rowNum++;
                        continue; // Bỏ qua dòng Header
                    }
                    List<String> cols = parseCsvLine(line);
                    String email = getCol(cols, 2);
                    if (email != null && !email.isBlank()) {
                        result.add(SheetRosterRow.builder()
                                .rowIndex(rowNum)
                                .classCode(getCol(cols, 0))
                                .rollNumber(getCol(cols, 1))
                                .email(email.trim().toLowerCase())
                                .memberCode(getCol(cols, 3))
                                .fullName(getCol(cols, 4))
                                .build());
                    }
                    rowNum++;
                }
            }
            log.info("Đọc động thành công {} dòng từ public CSV tab '{}'", result.size(), sheetName);
            return result;
        } catch (Exception e) {
            log.error("Import roster failed", e);
            throw new ApiException(ErrorCode.SHEET_ERROR,
                    extractGoogleApiError(e, "Không đọc được tab '" + sheetName + "'"));
        }
    }

    private List<String> parseCsvLine(String line) {
        List<String> result = new ArrayList<>();
        boolean inQuotes = false;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                result.add(sb.toString().trim());
                sb.setLength(0);
            } else {
                sb.append(c);
            }
        }
        result.add(sb.toString().trim());
        return result;
    }

    private String getCol(List<String> cols, int idx) {
        if (idx >= cols.size()) return null;
        String val = cols.get(idx);
        if (val == null) return null;
        val = val.replaceAll("^\"|\"$", "").trim();
        return val.isBlank() ? null : val;
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
                    extractGoogleApiError(e, "Không ghi được tab '" + sheetName + "'"));
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