package dto.response;

import lombok.*;
import java.time.Instant;
import java.time.LocalDate;

@Getter @Setter @Builder
public class SessionResponse {
    private Long id;
    private Long classId;
    private String classCode;
    private String className;
    private LocalDate sessionDate;
    private Instant startTime;
    private Instant endTime;
    private String room;
    private String status;
    private String qrToken;
    private String qrUrl;
    private Instant qrExpiresAt;
    private Long totalStudents;
    private Long checkedIn;
}
