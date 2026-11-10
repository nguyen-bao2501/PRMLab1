# AI-Assisted Code Review — Lab 3

## 1. Phạm vi và công cụ

Review này được thực hiện với **Codex AI (GPT-5)** trên nhánh
`ai-code-review-evidence`, so sánh với nhánh gốc `test`. Dart Analyzer là bước
kiểm tra tĩnh được thực hiện sau khi sửa. Nhánh này được chuẩn bị để mở pull request; thêm URL
của pull request vào đây sau khi đã push lên GitHub.

## 2. Phát hiện và quyết định

| ID | Tệp : dòng | Nhóm | Phát hiện | Quyết định và lý do kỹ thuật | Commit |
|---|---|---|---|---|---|
| CR-01 | `lib/services/class_repository.dart:168` | Functionality | Tham số `semester` thuộc hợp đồng `getClasses` nhưng hoàn toàn không được áp dụng khi dùng dữ liệu fallback. | **Accepted.** Lọc chính xác theo học kỳ trước khi lọc text, giúp kết quả fallback không lẫn lớp của kỳ khác. | `60e60b4` |
| CR-02 | `lib/services/class_repository.dart:186` | Reliability | Kiểm tra query đã dùng `trim()`, nhưng giá trị dùng để tìm kiếm lại không trim; truy vấn có khoảng trắng đầu/cuối sẽ không khớp. | **Accepted.** Chuẩn hoá một lần bằng `query.trim().toLowerCase()` trước khi so khớp. | `60e60b4` |
| CR-03 | `lib/viewmodels/live_attendance_view_model.dart:65` | Concurrency | Lời gọi bất đồng bộ tải danh sách điểm danh của phiên cũ có thể hoàn thành sau khi người dùng mở phiên mới và ghi đè roster hiện tại. | **Accepted.** Lưu session tại lúc gọi và chỉ cập nhật state khi ID vẫn khớp với session hiện tại. | `0119cc4` |
| CR-04 | `lib/viewmodels/class_view_model.dart:76` | UX / Error handling | Khi tải thống kê vắng lỗi, code cũ nuốt exception và giữ lại dữ liệu của lớp trước, dẫn đến thông tin sai. | **Accepted.** Xoá dữ liệu cũ trước khi tải và cung cấp `detailError` để UI có thể hiển thị trạng thái lỗi. | `745d2b9` |
| CR-05 | `lib/services/class_repository.dart:26` | Performance / Data freshness | AI đề xuất lưu cache roster ngoại tuyến dài hạn để giảm số lần gọi API. | **Rejected.** Danh sách điểm danh cần phản ánh check-in thời gian thực; cache bền lâu có thể làm giảng viên thấy tỷ lệ chuyên cần cũ. Chỉ dùng fallback mock khi API không khả dụng. | Không áp dụng |

## 3. Xác minh

- Đã chạy `git diff --check`: không có lỗi whitespace.
- Đã thử chạy `flutter analyze` cho ba tệp sửa và `flutter test test/api_service_test.dart`; môi trường runner không trả kết quả trước khi hết thời gian chờ 30 giây, nên cần chạy lại trên máy có Flutter SDK sẵn sàng trước khi nộp.
- Ba commit sửa độc lập, có thể truy vết bằng `git show 60e60b4`, `git show 0119cc4`, và `git show 745d2b9`.
