package repository;

import entity.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {
    List<Enrollment> findByClassRoomId(Long classId);
    boolean existsByClassRoomIdAndStudentId(Long classId, Long studentId);
    long countByClassRoomId(Long classId);
    void deleteByClassRoomIdAndStudentId(Long classId, Long studentId);
}
