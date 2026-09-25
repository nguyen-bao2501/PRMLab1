package dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateAttendanceRequest {

    @NotBlank(message = "Trạng thái không được để trống")
    private String status; // PRESENT, LATE, ABSENT, EXCUSED

    private String note;
}
