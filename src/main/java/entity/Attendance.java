package entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

@Entity
@Table(name = "attendances",
        uniqueConstraints = @UniqueConstraint(columnNames = {"session_id", "student_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Attendance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private Session session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private User student;

    @Enumerated(EnumType.STRING)
    private Status status = Status.PRESENT;

    @Column(name = "mark_code")
    private String markCode = "A";

    private String source = "APP";

    @Column(name = "check_in_time")
    private Instant checkInTime;

    @Column(name = "device_info")
    private String deviceInfo;

    @Column(name = "ip_address")
    private String ipAddress;

    private Double latitude;
    private Double longitude;
    private String note;

    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    public enum Status { PRESENT, LATE, ABSENT, EXCUSED }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (checkInTime == null) checkInTime = now;
        if (status == null) status = Status.PRESENT;
        if (markCode == null) markCode = "A";
        if (source == null) source = "APP";
    }
}
