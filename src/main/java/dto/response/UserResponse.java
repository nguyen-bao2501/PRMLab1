package dto.response;

import lombok.*;

@Getter @Setter @Builder
public class UserResponse {
    private Long id;
    private String email;
    private String fullName;
    private String avatarUrl;
    private String studentCode;
    private String role;
}
