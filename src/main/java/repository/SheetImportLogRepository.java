package repository;

import entity.SheetImportLog;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SheetImportLogRepository extends JpaRepository<SheetImportLog, Long> {
    List<SheetImportLog> findByClassIdOrderByImportedAtDesc(Long classId);
}
