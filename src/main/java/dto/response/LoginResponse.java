package dto.response;

import lombok.*;

@Getter @Setter @Builder
public class LoginResponse {
    private String accessToken;
    private String tokenType;
    private long expiresIn;
    private UserResponse user;
}
