package entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "sheet_import_logs")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SheetImportLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "class_id")
    private Long classId;

    @Column(name = "spreadsheet_id")
    private String spreadsheetId;

    @Column(name = "sheet_name")
    private String sheetName;

    @Column(name = "subject_code")
    private String subjectCode;

    @Column(name = "rows_imported")
    private Integer rowsImported = 0;

    @Column(name = "rows_skipped")
    private Integer rowsSkipped = 0;

    @Column(name = "imported_by")
    private Long importedBy;

    private String status = "SUCCESS";
    private String message;

    @Column(name = "imported_at", updatable = false)
    private Instant importedAt;

    @PrePersist
    void onCreate() { importedAt = Instant.now(); }
}