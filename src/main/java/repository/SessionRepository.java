package repository;

import entity.Session;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.Instant;
import java.util.List;

public interface SessionRepository extends JpaRepository<Session, Long> {
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select s from Session s where s.id = :id")
    java.util.Optional<Session> findForOpening(@org.springframework.data.repository.query.Param("id") Long id);
    boolean existsByClassRoomTeacherIdAndStatusNotAndStartTimeGreaterThanAndStartTimeLessThan(
            Long teacherId, Session.Status status, Instant after, Instant before);
    List<Session> findByClassRoomIdOrderBySessionDateDesc(Long classId);
    long countByClassRoomId(Long classId);
    List<Session> findByStatusAndQrExpiresAtLessThanEqual(Session.Status status, Instant expiresAt);
}
