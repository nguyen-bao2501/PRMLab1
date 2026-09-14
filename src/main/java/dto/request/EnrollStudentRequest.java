package dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class EnrollStudentRequest {

    @NotBlank @Email
    private String email;

    private String fullName;
    private String studentCode;
}
