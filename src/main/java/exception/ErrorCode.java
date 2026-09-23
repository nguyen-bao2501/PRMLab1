package exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum ErrorCode {
    SCHEDULE_CONFLICT("SCHEDULE_CONFLICT", "Giảng viên đã có tiết học trùng thời gian này", HttpStatus.CONFLICT),
    ATTENDANCE_WINDOW("ATTENDANCE_WINDOW", "Chỉ mở điểm danh trong thời gian tiết học (135 phút từ giờ bắt đầu)", HttpStatus.BAD_REQUEST),
    CLASS_NOT_FOUND("CLASS_NOT_FOUND", "Không tìm thấy lớp", HttpStatus.NOT_FOUND),
    SESSION_NOT_FOUND("SESSION_NOT_FOUND", "Không tìm thấy buổi điểm danh", HttpStatus.NOT_FOUND),
    SESSION_CLOSED("SESSION_CLOSED", "Buổi điểm danh đã kết thúc", HttpStatus.BAD_REQUEST),
    SESSION_NOT_OPEN("SESSION_NOT_OPEN", "Buổi điểm danh chưa mở", HttpStatus.BAD_REQUEST),
    QR_EXPIRED("QR_EXPIRED", "Mã QR đã hết hạn, vui lòng quét lại", HttpStatus.BAD_REQUEST),
    QR_INVALID("QR_INVALID", "Mã QR không hợp lệ", HttpStatus.BAD_REQUEST),
    ALREADY_CHECKED_IN("ALREADY_CHECKED_IN", "Bạn đã điểm danh rồi", HttpStatus.CONFLICT),
    NOT_IN_ROSTER("NOT_IN_ROSTER", "Email của bạn không có trong danh sách lớp", HttpStatus.FORBIDDEN),
    FORBIDDEN("FORBIDDEN", "Không có quyền thực hiện thao tác này", HttpStatus.FORBIDDEN),
    UNAUTHORIZED("UNAUTHORIZED", "Chưa xác thực", HttpStatus.UNAUTHORIZED),
    INVALID_TOKEN("INVALID_TOKEN", "Token không hợp lệ hoặc đã hết hạn", HttpStatus.UNAUTHORIZED),
    INVALID_GOOGLE_ACCOUNT("INVALID_GOOGLE_ACCOUNT", "Tài khoản Google không hợp lệ", HttpStatus.UNAUTHORIZED),
    CLASS_CODE_EXISTS("CLASS_CODE_EXISTS", "Mã lớp đã tồn tại", HttpStatus.CONFLICT),
    USER_NOT_FOUND("USER_NOT_FOUND", "Không tìm thấy người dùng", HttpStatus.NOT_FOUND),
    SHEET_ERROR("SHEET_ERROR", "Lỗi khi truy cập Google Sheet", HttpStatus.BAD_GATEWAY),
    SHEET_NOT_CONFIGURED("SHEET_NOT_CONFIGURED", "Lớp chưa cấu hình Google Sheet", HttpStatus.BAD_REQUEST),
    VALIDATION_FAILED("VALIDATION_FAILED", "Dữ liệu không hợp lệ", HttpStatus.BAD_REQUEST),
    INTERNAL_ERROR("INTERNAL_ERROR", "Lỗi hệ thống", HttpStatus.INTERNAL_SERVER_ERROR);

    private final String code;
    private final String message;
    private final HttpStatus status;

    ErrorCode(String code, String message, HttpStatus status) {
        this.code = code;
        this.message = message;
        this.status = status;
    }
}
