package repository;

import entity.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {
    List<Attendance> findBySessionId(Long sessionId);
    Optional<Attendance> findBySessionIdAndStudentId(Long sessionId, Long studentId);
    boolean existsBySessionIdAndStudentId(Long sessionId, Long studentId);
    long countBySessionId(Long sessionId);
    long countBySessionIdAndStatus(Long sessionId, Attendance.Status status);
    List<Attendance> findByStudentIdOrderByCheckInTimeDesc(Long studentId);
}
