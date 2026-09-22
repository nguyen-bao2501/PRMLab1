package service;

import dto.request.CreateClassRequest;
import dto.response.ClassResponse;
import entity.ClassRoom;
import entity.User;
import exception.ApiException;
import exception.ErrorCode;
import repository.ClassRepository;
import repository.ClassSheetRepository;
import repository.EnrollmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ClassService {

    private final ClassRepository classRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ClassSheetRepository classSheetRepository;

    @Transactional
    public ClassResponse create(CreateClassRequest req, User teacher) {
        if (classRepository.existsByClassCodeAndTeacherId(req.getClassCode(), teacher.getId())) {
            throw new ApiException(ErrorCode.CLASS_CODE_EXISTS);
        }
        ClassRoom cls = ClassRoom.builder()
                .classCode(req.getClassCode())
                .subjectCode(req.getSubjectCode())
                .teacher(teacher)
                .semester(req.getSemester())
                .totalSessions(0)
                .isActive(true)
                .build();
        classRepository.save(cls);
        return toResponse(cls);
    }

    public List<ClassResponse> listByTeacher(User teacher) {
        return classRepository.findByTeacherIdOrderByCreatedAtDesc(teacher.getId())
                .stream().filter(c -> Boolean.TRUE.equals(c.getIsActive()))
                .map(this::toResponse).collect(Collectors.toList());
    }

    public ClassResponse getById(Long id, User teacher) {
        ClassRoom cls = classRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.CLASS_NOT_FOUND));
        assertOwner(cls, teacher);
        return toResponse(cls);
    }

    @Transactional
    public void deactivate(Long id, User teacher) {
        ClassRoom cls = classRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.CLASS_NOT_FOUND));
        assertOwner(cls, teacher);
        cls.setIsActive(false);
    }

    public void assertOwner(ClassRoom cls, User teacher) {
        if (!cls.getTeacher().getId().equals(teacher.getId())) {
            throw new ApiException(ErrorCode.FORBIDDEN);
        }
    }

    private ClassResponse toResponse(ClassRoom c) {
        var mapping = classSheetRepository.findByClassRoomId(c.getId());
        String sheetName = mapping.map(cs -> cs.getSheetName()).orElse(null);

        return ClassResponse.builder()
                .id(c.getId())
                .classCode(c.getClassCode())
                .subjectCode(c.getSubjectCode())
                //.className(c.getClassName())
                .semester(c.getSemester())
                .totalSessions(c.getTotalSessions())
                .studentCount(enrollmentRepository.countByClassRoomId(c.getId()))
                .sheetName(sheetName)
                .spreadsheetId(mapping.map(cs -> cs.getSpreadsheetId()).orElse(null))
                .createdAt(c.getCreatedAt())
                .build();
    }
}
