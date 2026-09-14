package dto.response;

import lombok.*;

import java.time.Instant;

@Getter @Setter @Builder
public class ClassResponse {
    private Long id;
    private String classCode;
    private String subjectCode;
    private String className;
    private String semester;
    private Integer totalSessions;
    private Long studentCount;
    private String sheetName;
    private Instant createdAt;
}