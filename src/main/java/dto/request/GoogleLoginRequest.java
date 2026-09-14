package dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class GoogleLoginRequest {

    @NotBlank(message = "idToken không được để trống")
    private String idToken;

    /**
     * Không dùng để map tài khoản. Mã sinh viên luôn lấy từ roster Google Sheet,
     * vì dữ liệu từ client không đáng tin cậy.
     */
    @Deprecated
    private String studentCode;
}
