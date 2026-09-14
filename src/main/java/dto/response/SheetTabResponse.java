package dto.response;

import lombok.*;

@Getter @Setter @Builder
public class SheetTabResponse {
    private String sheetName;
    private String subjectCode;
    private String classCode;
}
