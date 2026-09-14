package dto.response;

import lombok.*;

@Getter @Setter @Builder
public class SheetImportResponse {
    private Long classId;
    private String spreadsheetId;
    private String sheetName;
    private String subjectCode;
    private String classCodeFromTab;
    private int rowsImported;
    private int rowsSkipped;
    private int totalInSheet;
}
