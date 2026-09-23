package service;

import com.example.prm.DemoApplication;
import dto.request.ImportScheduleRequest;
import entity.User;
import exception.ApiException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import repository.*;
import java.time.LocalDate;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(classes=DemoApplication.class, properties={
    "spring.datasource.url=jdbc:h2:mem:ocrimport;MODE=MSSQLServer;DB_CLOSE_DELAY=-1",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa", "spring.datasource.password=",
    "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect"
})
class ScheduleImportIntegrationTest {
    @Autowired ScheduleImportService service;
    @Autowired UserRepository users;
    @Autowired ClassRepository classes;
    @Autowired SessionRepository sessions;
    @Autowired AttendanceRepository attendances;
    @Test void batchIsAtomicAndRetryIsIdempotentInDatabase() {
        var teacher=users.save(User.builder().email("ocr-teacher@example.test").role(User.Role.TEACHER).build());
        var first=new ImportScheduleRequest.Lesson("SE1917","PRN232","NVH 602",LocalDate.of(2026,9,7),1);
        var conflict=new ImportScheduleRequest.Lesson("SE1917","PRM393","NVH 602",LocalDate.of(2026,9,7),1);
        assertThrows(ApiException.class,()->service.importSchedule(new ImportScheduleRequest("FA2026",List.of(first,conflict)),teacher));
        assertTrue(classes.findByTeacherIdOrderByCreatedAtDesc(teacher.getId()).isEmpty());
        assertEquals(0,sessions.count());
        var second=new ImportScheduleRequest.Lesson("SE1917","PRM393","NVH 602",LocalDate.of(2026,9,7),2);
        var valid=new ImportScheduleRequest("FA2026",List.of(first,second));
        assertEquals(2,service.importSchedule(valid,teacher).get("createdLessons"));
        assertEquals(2,service.importSchedule(valid,teacher).get("skipped"));
        assertEquals(2,classes.findByTeacherIdOrderByCreatedAtDesc(teacher.getId()).size());
        assertEquals(2,sessions.count());
        assertEquals(0,attendances.count());
    }
}
