package dto.request;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class DevLoginRequest {
    private String email;
    private String role;
}
