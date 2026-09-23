package config;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import javax.sql.DataSource;
import java.nio.charset.StandardCharsets;

/** Hibernate schema update does not widen existing SQL Server CHECK constraints. */
@Component
@RequiredArgsConstructor
public class ScheduledStatusMigration implements ApplicationRunner {
    private final DataSource dataSource;
    @Override
    public void run(ApplicationArguments args) throws Exception {
        try (var connection = dataSource.getConnection()) {
            if (!connection.getMetaData().getDatabaseProductName().equals("Microsoft SQL Server")) return;
            try (var stream = new ClassPathResource("db/migration/scheduled_status_sqlserver.sql").getInputStream();
                 var statement = connection.createStatement()) {
                statement.execute(new String(stream.readAllBytes(), StandardCharsets.UTF_8).replace("\uFEFF", ""));
            } catch (Exception e) {
                // XACT_ABORT rolls back SQL errors; ensure any open transaction is closed.
                try (var rollback = connection.createStatement()) {
                    rollback.execute("IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION");
                }
                throw e;
            }
        }
    }
}
