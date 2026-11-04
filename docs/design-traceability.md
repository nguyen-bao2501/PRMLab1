# Design Traceability Matrix (Bảng Đối Soát Thiết Kế) — Lab 3

Tài liệu này đối soát chi tiết toàn bộ các màn hình, luồng nghiệp vụ và thành phần giao diện từ bản thiết kế **Figma Lab 2** sang mã nguồn **Flutter** của Lab 3.

---

## 1. Bảng ma trận đối soát màn hình & luồng người dùng

| Mã màn hình Figma | Tên màn hình | Tuyến đường (Route) & Widget triển khai | ViewModel quản lý | Nguồn dữ liệu (Data Source) | Trạng thái hiển thị |
|---|---|---|---|---|---|
| **01.01** | Đăng nhập | `lib/screens/auth/login_screen.dart` | `AuthViewModel` | Firebase Authentication & Google Sign-In | Hoàn thành |
| **02.01** | Tổng quan giảng dạy | `lib/screens/dashboard/dashboard_screen.dart` | `DashboardViewModel` | `ClassRepository` & Firebase Remote Config | Hoàn thành |
| **03.01** | Lớp học của tôi | `lib/screens/classes/class_list_screen.dart` | `ClassViewModel` | `ClassRepository` (REST API `/v1/classes`) | Hoàn thành |
| **03.02** | Chi tiết lớp học | `lib/screens/classes/class_detail_screen.dart` | `ClassViewModel` | `ClassRepository` (Chi tiết lớp, thống kê vắng) | Hoàn thành |
| **03.03** | Nhập sinh viên từ Sheet | `lib/screens/classes/import_sheet_screen.dart` | `ClassViewModel` | Google Sheets API & `ClassRepository` | Hoàn thành |
| **04.01** | Lịch dạy (Lịch tuần) | `lib/screens/schedule/schedule_week_screen.dart` | `ScheduleViewModel` | `ClassRepository` (Lịch dạy theo ngày/tuần) | Hoàn thành |
| **04.02** | Xếp lịch tiết học | `lib/screens/schedule/create_schedule_screen.dart` | `ScheduleViewModel` | `ClassRepository` (Tạo lịch buổi học mới) | Hoàn thành |
| **04.03** | Chi tiết tiết học | `lib/screens/schedule/session_detail_screen.dart` | `ScheduleViewModel` | `ClassRepository` (Thông tin slot & phòng học) | Hoàn thành |
| **04.04** | Điểm danh trực tiếp & QR | `lib/screens/attendance/live_attendance_screen.dart` | `LiveAttendanceViewModel` | QR Token generator & Firebase Analytics | Hoàn thành |
| **05.02** | Báo cáo điểm danh | `lib/screens/reports/attendance_report_screen.dart` | `ReportViewModel` | Firebase Cloud Storage & Google Sheets | Hoàn thành |
| **06.01** | Hồ sơ & Firebase Demo | `lib/screens/profile/profile_firebase_screen.dart` | `FirebaseDemoViewModel` | Firebase Auth, Storage, FCM, Crashlytics, Remote Config | Hoàn thành |

---

## 2. Đối soát Design Tokens & Thành phần dùng chung (Widgets)

| Token / Component Figma | Tên mã nguồn Flutter | Thư mục định nghĩa | Ghi chú & Quy chuẩn |
|---|---|---|---|
| Màu xanh thẫm Hero Card & Header (`#263835`) | `AppColors.primaryDark` | `lib/theme/app_colors.dart` | Màu chủ đạo thương hiệu |
| Màu vàng đồng Nút tạo & xếp lịch (`#C19342`) | `AppColors.accentGold` | `lib/theme/app_colors.dart` | Nút hành động chính (Primary Call-To-Action) |
| Màu đỏ nút kết thúc điểm danh (`#C0392B`) | `AppColors.dangerRed` | `lib/theme/app_colors.dart` | Thao tác cảnh báo / Chốt vắng |
| Màu nền Campus xám nhạt (`#EBF1ED`) | `AppColors.scaffoldBg` | `lib/theme/app_colors.dart` | Nền toàn bộ Scaffold |
| App Bar tiêu đề & Avatar tròn | `CampusAppBar` | `lib/widgets/campus_app_bar.dart` | Chiều cao 60dp, avatar chữ cái 'N' |
| Thẻ Hero xanh thẫm | `CampusHeroCard` | `lib/widgets/campus_cards.dart` | Bo góc 16dp, pill cập nhật thời gian |
| Thẻ thống kê 2 cột số to | `MetricStatCard` | `lib/widgets/campus_cards.dart` | Icon màu bên trái + Label + Số to |
| Thẻ lớp học | `ClassItemCard` | `lib/widgets/campus_cards.dart` | Icon sách, tag FA2026, nút Mở lớp ↗ |
| Thẻ tiết học hôm nay / sắp tới | `TeachingSessionCard` | `lib/widgets/campus_cards.dart` | Viền xanh khi đang active |
| Badge trạng thái con nhộng | `StatusBadgePill` | `lib/widgets/campus_cards.dart` | Success (xanh lá), Warning (vàng cam), Danger (đỏ), Neutral (xám) |
| Bộ 3 widget trạng thái tải | `AppLoadingView`, `AppEmptyView`, `AppErrorView` | `lib/widgets/state_views.dart` | Đáp ứng tiêu chuẩn xử lý Loading, Empty, Error trên mọi màn hình |

---

## 3. Nhật ký điều chỉnh thiết kế (Design Deviations & Rationales)

Không có sự khác biệt hoặc cắt xén giao diện so với bản thiết kế Figma của Lab 2:
- Toàn bộ 10 màn hình đã được dựng đúng chuẩn từng chi tiết, mã màu, bo góc và thứ tự phân cấp thị giác.
- Bổ sung thêm nút **"Xuất báo cáo PDF lên Firebase Cloud Storage"** tại màn hình `05.02 — Báo cáo điểm danh` để thỏa mãn yêu cầu xuất file và lưu trữ đám mây của Lab 3.
