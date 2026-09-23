package service;

import dto.request.ImportScheduleRequest;
import entity.*;
import exception.ApiException;
import exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import repository.*;
import java.time.*;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ScheduleImportService {
    private final ClassRepository classes;
    private final SessionRepository sessions;
    private final UserRepository users;
    private static final LocalTime[] SLOTS = {
        LocalTime.of(7,0), LocalTime.of(9,30), LocalTime.of(12,30),
        LocalTime.of(15,0), LocalTime.of(17,30), LocalTime.of(20,0)
    };

    /** Transactional import: a conflict rolls back the entire batch. Past lessons
     * remain SCHEDULED and must never fabricate an attendance result. */
    @Transactional
    public Map<String, Integer> importSchedule(ImportScheduleRequest request, User teacher) {
        users.lockForScheduleImport(teacher.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.USER_NOT_FOUND));
        String semester = request.semester().trim();
        var owned = new ArrayList<>(classes.findByTeacherIdOrderByCreatedAtDesc(teacher.getId()));
        var existing = new ArrayList<Session>();
        for (var c : owned) existing.addAll(sessions.findByClassRoomIdOrderBySessionDateDesc(c.getId()));
        int createdClasses = 0, createdLessons = 0, skipped = 0;
        for (var row : request.lessons()) {
            var date = row.date();
            if (date.getYear() < 2000 || date.getYear() > 2100 || row.slot() < 1 || row.slot() > 6)
                throw new ApiException(ErrorCode.VALIDATION_FAILED);
            Instant start = date.atTime(SLOTS[row.slot()-1]).atZone(ZoneId.of("Asia/Ho_Chi_Minh")).toInstant();
            var matching = owned.stream().filter(c -> Boolean.TRUE.equals(c.getIsActive())
                    && row.classCode().equals(c.getClassCode()) && row.subjectCode().equals(c.getSubjectCode())
                    && semester.equals(c.getSemester())).toList();
            if (matching.size() > 1) throw new ApiException(ErrorCode.CLASS_CODE_EXISTS);
            ClassRoom classroom = matching.isEmpty() ? null : matching.get(0);
            final ClassRoom found = classroom;
            var duplicate = existing.stream().filter(s -> s.getStatus() != Session.Status.CANCELLED
                    && found != null && Objects.equals(s.getClassRoom().getId(), found.getId()) && start.equals(s.getStartTime())).findFirst();
            if (duplicate.isPresent()) {
                if (!Objects.equals(duplicate.get().getRoom(), row.room().trim()))
                    throw new ApiException(ErrorCode.SCHEDULE_CONFLICT);
                skipped++;
                continue;
            }
            if (existing.stream().anyMatch(s -> s.getStatus() != Session.Status.CANCELLED
                    && s.getStartTime().isAfter(start.minusSeconds(135*60))
                    && s.getStartTime().isBefore(start.plusSeconds(135*60))))
                throw new ApiException(ErrorCode.SCHEDULE_CONFLICT);
            if (classroom == null) {
                classroom = classes.save(ClassRoom.builder().teacher(teacher).classCode(row.classCode())
                        .subjectCode(row.subjectCode()).semester(semester).isActive(true).totalSessions(0).build());
                owned.add(classroom);
                createdClasses++;
            }
            var lesson = Session.builder().classRoom(classroom).sessionDate(date).startTime(start)
                    .room(row.room().trim()).status(Session.Status.SCHEDULED).build();
            sessions.save(lesson);
            existing.add(lesson);
            classroom.setTotalSessions(classroom.getTotalSessions()+1);
            createdLessons++;
        }
        return Map.of("createdClasses",createdClasses,"createdLessons",createdLessons,"skipped",skipped);
    }
}
