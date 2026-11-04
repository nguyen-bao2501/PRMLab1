# Analytics Event Plan (Kế Hoạch Sự Kiện Phân Tích) — Lab 3

Tài liệu này định nghĩa chi tiết các sự kiện phân tích người dùng được gắn vào ứng dụng thông qua **Firebase Analytics**, tuân thủ nghiêm ngặt định dạng mẫu tại Phụ lục A (Appendix A) của tài liệu hướng dẫn Lab 3.

> [!NOTE]
> Mọi tham số đều tuyệt đối **không chứa thông tin định danh cá nhân (No PII)** như họ tên sinh viên hoặc địa chỉ email. Mã định danh người dùng (`User ID`) được thiết lập thông qua phương thức `setUserId()` của Firebase Analytics sau khi đăng nhập thành công.

---

## Bảng kế hoạch sự kiện (Analytics Events Specification)

| Tên sự kiện (`Event`) | Thời điểm kích hoạt (`Trigger`) | Tham số truyền kèm (`Parameters & Type`) | Câu hỏi sản phẩm cần giải đáp (`Question it answers`) |
|---|---|---|---|
| **`login`** | Đăng nhập Google thành công vào hệ thống | `method` *(string)*: "google" | Có bao nhiêu giảng viên quay lại sử dụng ứng dụng mỗi tuần? |
| **`logout`** | Người dùng bấm Đăng xuất tại màn hình Hồ sơ | *(không tham số)* | Thời lượng trung bình của một phiên làm việc trước khi giảng viên đăng xuất là bao lâu? |
| **`search`** | Người dùng thực hiện tìm kiếm tại màn hình Lớp học của tôi (03.01) | `search_term` *(string)*<br>`result_count` *(int)* | Những môn học hoặc mã lớp nào được tìm kiếm nhiều nhất, và từ khóa nào không trả về kết quả? |
| **`view_class_detail`** | Mở xem màn hình Chi tiết lớp học (03.02) | `class_id` *(string)*<br>`subject_code` *(string)* | Môn học nào được giảng viên theo dõi tiến độ chi tiết nhiều nhất sau khi tìm kiếm? |
| **`view_schedule`** | Người dùng chuyển ngày trên dải lịch tuần (04.01) | `date` *(string)*<br>`session_count` *(int)* | Những ngày nào trong tuần có mật độ giảng dạy cao nhất và được tra cứu thường xuyên? |
| **`start_live_attendance`** | Bấm mở phiên điểm danh trực tiếp & hiển thị mã QR (04.04) | `session_id` *(string)*<br>`slot` *(int)*<br>`room` *(string)* | Ca học (Slot) nào và phòng học nào thường xuyên diễn ra hoạt động điểm danh đúng giờ nhất? |
| **`export_attendance_report`** | Tạo file PDF và tải lên Firebase Cloud Storage thành công (05.02) | `class_code` *(string)*<br>`attended_count` *(int)*<br>`total_count` *(int)* | Tỷ lệ buổi học được giảng viên xuất và lưu trữ báo cáo lên đám mây đạt bao nhiêu phần trăm? |

---

## Bản đồ đối soát với hành trình người dùng (User Flows Traceability)

- **Flow 1: Xác thực & Điều hướng**:
  - `login` $\rightarrow$ Đăng nhập thành công, điều hướng vào Dashboard.
  - `logout` $\rightarrow$ Giảng viên kết thúc phiên làm việc, xóa dữ liệu đệm cục bộ.
- **Flow 2: Quản lý lớp học & Tra cứu**:
  - `search` $\rightarrow$ Tìm kiếm mã môn (PRM393, PRN232...).
  - `view_class_detail` $\rightarrow$ Xem chi tiết số lượng buổi học và danh sách sinh viên vắng nhiều nhất.
- **Flow 3: Quản lý lịch dạy & Điểm danh đám mây**:
  - `view_schedule` $\rightarrow$ Tra cứu lịch dạy tuần.
  - `start_live_attendance` $\rightarrow$ Mở mã QR động và giám sát sinh viên quét thẻ thời gian thực.
  - `export_attendance_report` $\rightarrow$ Kết thúc điểm danh, tạo file PDF báo cáo và tải lên Firebase Cloud Storage an toàn dưới đường dẫn `reports/{uid}/...`.
