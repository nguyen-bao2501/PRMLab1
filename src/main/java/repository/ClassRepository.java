package repository;

import entity.ClassRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ClassRepository extends JpaRepository<ClassRoom, Long> {
    List<ClassRoom> findByTeacherIdOrderByCreatedAtDesc(Long teacherId);
    boolean existsByClassCode(String classCode);
}
