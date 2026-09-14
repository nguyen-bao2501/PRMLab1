package dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CreateClassRequest {

    @NotBlank(message = "classCode không được để trống")
    private String classCode;
    @NotBlank(message = "subjectCode không được để trống")
    private String subjectCode;
    private String semester;
}
