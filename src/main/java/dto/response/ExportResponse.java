package dto.response;

import lombok.*;

@Getter @Setter @Builder
public class ExportResponse {
    private Long sessionId;
    private String spreadsheetId;
    private String spreadsheetUrl;
    private long presentCount;
    private long absentCount;
    private long totalStudents;
    private String sheetName;
}
