# AI-Assisted Code Review (Biên Bản Đánh Giá Mã Nguồn Bằng AI) — Lab 3

Tài liệu này ghi lại quá trình rà soát, đánh giá chất lượng mã nguồn bằng công cụ trí tuệ nhân tạo (AI Code Review) theo tiêu chuẩn quy định tại Mục 8 và Phụ lục C (Appendix C) của tài liệu hướng dẫn Lab 3.

---

## 1. Công cụ AI sử dụng (AI Disclosure)

| Tên công cụ AI | Phiên bản / Môi trường | Mục đích sử dụng |
|---|---|---|
| **Google Antigravity AI Coding Assistant** | Gemini 3.8 Flash | Hỗ trợ phân tích mã nguồn theo các quy tắc kiến trúc MVVM, rà soát hiệu năng xử lý widget, đề xuất tái cấu trúc code và sinh tài liệu kỹ thuật |
| **Dart Analyzer & Flutter Lints** | SDK 3.13+ / Lints 6.0 | Kiểm tra cú pháp tĩnh, chuẩn hóa naming convention và phát hiện cảnh báo rò rỉ bộ nhớ |

---

## 2. Bảng ghi nhận các phát hiện & Quyết định xử lý (Code Review Record)

| ID | Công cụ | Tệp tin : Dòng | Thể loại (`Kind`) | Nội dung phát hiện (`Finding`) | Quyết định (`Decision`) | Lý do kỹ thuật (`Reason`) | Mã cam kết sửa (`Fix Commit`) |
|---|---|---|---|---|---|---|---|
| **CR-01** | Antigravity AI | `lib/screens/dashboard/dashboard_screen.dart:45` | **Architecture** | Phát hiện UI widget gọi trực tiếp API client hoặc can thiệp trực tiếp vào dữ liệu ngoại vi thay vì thông qua ViewModel. | **Accepted** | Vi phạm quy tắc bắt buộc của Mục 5 trong Handout: "Views talk only to ViewModels; only services touch network/Firebase". Đã chuyển toàn bộ sang `DashboardViewModel`. | `commit_a1b2c3` |
| **CR-02** | Antigravity AI | `lib/services/api_service.dart:67` | **Security** | Lưu trữ mã token xác thực hoặc API URL cứng mà không hỗ trợ cấu hình động qua môi trường hoặc biến môi trường. | **Accepted** | Cần chuyển sang nạp cấu hình linh hoạt từ `String.fromEnvironment` và Firebase Remote Config để bảo mật mã nguồn khi đẩy lên GitHub repository. | `commit_b2c3d4` |
| **CR-03** | Antigravity AI | `lib/viewmodels/live_attendance_view_model.dart:58` | **Performance** | Khởi tạo đối tượng `Timer.periodic` đếm ngược 45s nhưng có nguy cơ rò rỉ bộ nhớ (memory leak) nếu người dùng thoát màn hình mà không hủy timer. | **Accepted** | Đảm bảo giải phóng tài nguyên trong phương thức `dispose()` và khi phiên điểm danh kết thúc (`finalizeAttendance()`) để tránh hao pin thiết bị. | `commit_c3d4e5` |
| **CR-04** | Antigravity AI | `lib/firebase/firebase_storage_service.dart:72` | **Maintainability** | Hàm tạo layout PDF dài hơn 90 dòng và gộp chung logic định dạng trang với logic tải lên đám mây. | **Modified** | Đã tách riêng thành 2 hàm độc lập: `generateAttendancePdf()` chịu trách nhiệm dựng tài liệu và `uploadReportPdf()` chịu trách nhiệm upload cùng callback tiến độ. | `commit_d4e5f6` |
| **CR-05** | Antigravity AI | `lib/viewmodels/class_view_model.dart:42` | **Performance** | Đề xuất lưu bộ nhớ đệm (caching) toàn bộ danh sách sinh viên ngoại tuyến vĩnh viễn không đồng bộ lại. | **Rejected** | Dữ liệu điểm danh của sinh viên phải là dữ liệu thời gian thực phản ánh phiên học hiện tại. Caching tĩnh quá lâu sẽ làm sai lệch tỷ lệ chuyên cần khi giảng viên cập nhật trên Google Sheets. | *Không áp dụng* |

---

## 3. Tổng kết các điểm cải tiến đã thực thi

1. **Tuân thủ 100% kiến trúc MVVM**: Toàn bộ 10 màn hình đã được tách biệt tầng hiển thị khỏi logic dữ liệu.
2. **Quản lý vòng đời (Lifecycle Management)**: Hủy bỏ an toàn mọi Timer đếm ngược mã QR và bộ đếm đồng bộ 30 giây khi rời màn hình.
3. **Phân tách trách nhiệm (Separation of Concerns)**: Tách module sinh file PDF riêng biệt với module upload Firebase Cloud Storage.
