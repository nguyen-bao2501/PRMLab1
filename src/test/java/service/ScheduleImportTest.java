package service;

import dto.request.ImportScheduleRequest;
import entity.*;
import exception.ApiException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import repository.*;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ScheduleImportTest {
    final ClassRepository classes=mock(ClassRepository.class);
    final SessionRepository sessions=mock(SessionRepository.class);
    final UserRepository users=mock(UserRepository.class);
    final User teacher=User.builder().id(1L).build();
    final ScheduleImportService service=new ScheduleImportService(classes,sessions,users);
    @BeforeEach void setup() {
        when(users.lockForScheduleImport(1L)).thenReturn(Optional.of(teacher));
        when(classes.findByTeacherIdOrderByCreatedAtDesc(1L)).thenReturn(List.of());
        when(classes.save(any())).thenAnswer(inv->{ ClassRoom c=inv.getArgument(0); c.setId((long)c.getSubjectCode().hashCode()); return c; });
    }
    ImportScheduleRequest.Lesson row(String subject,int slot) {
        return new ImportScheduleRequest.Lesson("SE1917",subject,"NVH 602",LocalDate.of(2026,9,7),slot);
    }
    @Test void importsPastWeekWithoutInventingAttendanceAndSeparatesSubjects() {
        var result=service.importSchedule(new ImportScheduleRequest("FA2026",List.of(row("PRN232",1),row("PRM393",2))),teacher);
        assertEquals(2,result.get("createdClasses"));
        assertEquals(2,result.get("createdLessons"));
        verify(sessions,times(2)).save(argThat(s->s.getStatus()==Session.Status.SCHEDULED && s.getQrExpiresAt()==null));
    }
    @Test void repeatImportSkipsExistingLessons() {
        ClassRoom c=ClassRoom.builder().id(2L).teacher(teacher).classCode("SE1917").subjectCode("PRN232").semester("FA2026").isActive(true).totalSessions(1).build();
        when(classes.findByTeacherIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(c));
        // A separate entity instance with the same ID must still match.
        Session existing=Session.builder().classRoom(ClassRoom.builder().id(2L).build()).room("NVH 602")
                .startTime(Instant.parse("2026-09-07T00:00:00Z")).status(Session.Status.SCHEDULED).build();
        when(sessions.findByClassRoomIdOrderBySessionDateDesc(2L)).thenReturn(List.of(existing));
        var result=service.importSchedule(new ImportScheduleRequest("FA2026",List.of(row("PRN232",1))),teacher);
        assertEquals(1,result.get("skipped"));
        verify(sessions,never()).save(any());
        verify(classes,never()).save(any());
    }
    @Test void refusesTwoSubjectsInSameSlot() {
        assertThrows(ApiException.class,()->service.importSchedule(new ImportScheduleRequest("FA2026",List.of(row("PRN232",1),row("PRM393",1))),teacher));
    }
}
