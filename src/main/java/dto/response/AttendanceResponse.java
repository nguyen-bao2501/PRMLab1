package dto.response;

import lombok.*;
import java.time.Instant;

@Getter @Setter @Builder
public class AttendanceResponse {
    private Long id;
    private Long sessionId;
    private Long studentId;
    private String studentName;
    private String studentCode;
    private String email;
    private String status;
    private String markCode;
    private Instant checkInTime;
    private String ipAddress;
}
