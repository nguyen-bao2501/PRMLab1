package dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

@Getter @Setter @Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;
    private Object errors;
    private long timestamp;

    public static <T> ApiResponse<T> ok(T data) {
        return ApiResponse.<T>builder()
                .success(true).message("OK").data(data)
                .timestamp(System.currentTimeMillis()).build();
    }

    public static <T> ApiResponse<T> ok(String msg, T data) {
        return ApiResponse.<T>builder()
                .success(true).message(msg).data(data)
                .timestamp(System.currentTimeMillis()).build();
    }

    public static <T> ApiResponse<T> error(String msg, Object errors) {
        return ApiResponse.<T>builder()
                .success(false).message(msg).errors(errors)
                .timestamp(System.currentTimeMillis()).build();
    }
}

