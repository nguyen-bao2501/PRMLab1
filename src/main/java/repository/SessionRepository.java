package repository;

import entity.Session;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.Instant;
import java.util.List;

public interface SessionRepository extends JpaRepository<Session, Long> {
    List<Session> findByClassRoomIdOrderBySessionDateDesc(Long classId);
    long countByClassRoomId(Long classId);
    List<Session> findByStatusAndQrExpiresAtLessThanEqual(Session.Status status, Instant expiresAt);
}
