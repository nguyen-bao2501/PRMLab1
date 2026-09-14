package  repository;

import  entity.ClassSheet;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ClassSheetRepository extends JpaRepository<ClassSheet, Long> {
    Optional<ClassSheet> findByClassRoomId(Long classId);
}