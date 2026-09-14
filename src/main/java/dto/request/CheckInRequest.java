package dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CheckInRequest {

    @NotBlank(message = "qrToken không được để trống")
    private String qrToken;

    private Double latitude;
    private Double longitude;
    private String deviceInfo;
}
