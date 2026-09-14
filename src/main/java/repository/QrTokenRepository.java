package repository;

import entity.QrToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import java.time.Instant;
import java.util.Optional;

public interface QrTokenRepository extends JpaRepository<QrToken, Long> {
    Optional<QrToken> findByToken(String token);
    @Modifying
    @Query("DELETE FROM QrToken q WHERE q.expiresAt < :now")
    int deleteExpired(Instant now);
}
