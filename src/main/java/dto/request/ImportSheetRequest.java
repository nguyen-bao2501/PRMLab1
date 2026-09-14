package dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ImportSheetRequest {

    @NotBlank(message = "spreadsheetId không được để trống")
    private String spreadsheetId;

    @NotBlank(message = "sheetName không được để trống")
    private String sheetName;
}
