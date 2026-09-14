package entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "classes")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ClassRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "class_code", unique = true, nullable = false)
    private String classCode;

    @Column(name = "subject_code")
    private String subjectCode;

//    @Column(name = "class_name", nullable = false)
//    private String className;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id", nullable = false)
    private User teacher;

    private String semester;

    @Column(name = "total_sessions")
    private Integer totalSessions = 0;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
        if (isActive == null) isActive = true;
        if (totalSessions == null) totalSessions = 0;
    }
}