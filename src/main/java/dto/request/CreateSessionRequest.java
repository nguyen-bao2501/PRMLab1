package dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.time.Instant;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CreateSessionRequest {

    @NotNull(message = "classId không được để trống")
    private Long classId;

    private String room;
    private Instant startTime;
}
