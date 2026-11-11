package dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.List;

public record ImportScheduleRequest(
        @NotBlank @Size(max=40) String semester,
        @NotNull @Size(min=1, max=100) List<@NotNull @Valid Lesson> lessons,
        Boolean applyWholeSemester,
        LocalDate applyFrom,
        LocalDate applyUntil) {
    public ImportScheduleRequest(String semester, List<Lesson> lessons) {
        this(semester, lessons, false, null, null);
    }

    public record Lesson(
            @NotBlank @Pattern(regexp="[A-Z]{2}[0-9]{4,6}") String classCode,
            @NotBlank @Pattern(regexp="[A-Z]{2,4}[0-9]{3}") String subjectCode,
            @NotBlank @Size(max=80) String room,
            @NotNull LocalDate date,
            @Min(1) @Max(6) int slot) {}
}
