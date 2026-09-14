package dto;

import lombok.*;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class SheetRosterRow {
    private int rowIndex;
    private String classCode;
    private String rollNumber;
    private String email;
    private String memberCode;
    private String fullName;
}
