package entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

@Entity
@Table(name = "qr_tokens")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class QrToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private Session session;

    @Column(unique = true, nullable = false)
    private String token;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "is_used")
    private Boolean isUsed = false;

    @Column(name = "created_at", updatable = false)
    private Instant createdAt;
}
