# Architecture & Layering Specification (Tài Liệu Kiến Trúc) — Lab 3

Hệ thống được xây dựng theo mô hình **MVVM (Model - View - ViewModel)** kết hợp với thư viện quản lý trạng thái **Provider**, tuân thủ nguyên tắc phụ thuộc một chiều (Dependencies point downwards only).

---

## 1. Cấu trúc thư mục dự án (`lib/`)

```
lib/
├── firebase/         # Triển khai các dịch vụ Firebase (Auth, Storage, FCM, Analytics, Crashlytics, Remote Config)
├── models/           # Các lớp mô hình dữ liệu Dart thuần túy (UserModel, ClassModel, SessionModel, UiState)
├── screens/          # Tầng View chứa toàn bộ 10 màn hình Figma và màn hình Firebase Demo
│   ├── attendance/   # Màn hình phiên điểm danh trực tiếp & mã QR (04.04)
│   ├── auth/         # Màn hình đăng nhập tài khoản Google (01.01)
│   ├── classes/      # Màn hình danh sách lớp (03.01), chi tiết lớp (03.02), nhập sinh viên (03.03)
│   ├── dashboard/    # Màn hình tổng quan giảng dạy (02.01)
│   ├── profile/      # Màn hình hồ sơ giảng viên & khu vực chấm điểm Firebase Demo Area
│   ├── reports/      # Màn hình báo cáo điểm danh & xuất PDF Cloud Storage (05.02)
│   └── schedule/     # Màn hình lịch tuần (04.01), tạo lịch (04.02), chi tiết tiết (04.03)
├── services/         # Tầng Repository và API Client giao tiếp backend Spring Boot
├── theme/            # Hệ thống Design Tokens từ Figma (Màu sắc, Typography, Kích thước bo góc)
├── utils/            # Hằng số và hàm tiện ích dùng chung
├── widgets/          # Thư viện widget tái sử dụng (App Bar, Buttons, Cards, Status Pills, State Views)
└── main.dart         # Điểm khởi động ứng dụng, thiết lập MultiProvider và điều hướng auth state
```

---

## 2. Sơ đồ các tầng kiến trúc (MVVM Layer Diagram)

```mermaid
graph TD
    subgraph View Layer [Screens & Reusable Widgets]
        UI_Login[LoginScreen 01.01]
        UI_Dash[DashboardScreen 02.01]
        UI_Classes[ClassList 03.01 & Detail 03.02 & Import 03.03]
        UI_Sched[ScheduleWeek 04.01 & Create 04.02 & Detail 04.03]
        UI_Att[LiveAttendanceScreen 04.04]
        UI_Report[AttendanceReportScreen 05.02]
        UI_Profile[ProfileFirebaseScreen 06.01]
    end

    subgraph ViewModel Layer [ViewModels with Provider]
        VM_Auth[AuthViewModel]
        VM_Dash[DashboardViewModel]
        VM_Class[ClassViewModel]
        VM_Sched[ScheduleViewModel]
        VM_Att[LiveAttendanceViewModel]
        VM_Report[ReportViewModel]
        VM_FBDemo[FirebaseDemoViewModel]
    end

    subgraph Service & Repository Layer [Services & Firebase Wrappers]
        Repo[ClassRepository / ApiService]
        F_Auth[FirebaseAuthService]
        F_Storage[FirebaseStorageService]
        F_FCM[FirebaseNotificationService]
        F_Analytics[FirebaseAnalyticsService]
        F_Crash[FirebaseCrashlyticsService]
        F_Config[FirebaseRemoteConfigService]
    end

    subgraph Data Sources [Cloud & Backend]
        API[(Spring Boot REST API)]
        FB_Cloud[(Firebase Services: Auth, Storage, FCM, Analytics, Crashlytics, RemoteConfig)]
    end

    UI_Login --> VM_Auth
    UI_Dash --> VM_Dash
    UI_Classes --> VM_Class
    UI_Sched --> VM_Sched
    UI_Att --> VM_Att
    UI_Report --> VM_Report
    UI_Profile --> VM_FBDemo

    VM_Auth --> F_Auth & F_Analytics
    VM_Dash --> Repo & F_Config & F_Analytics
    VM_Class --> Repo & F_Analytics
    VM_Sched --> Repo & F_Analytics
    VM_Att --> Repo & F_Crash & F_Analytics
    VM_Report --> Repo & F_Storage & F_Analytics
    VM_FBDemo --> F_Auth & F_Storage & F_FCM & F_Crash & F_Config

    Repo --> API
    F_Auth & F_Storage & F_FCM & F_Analytics & F_Crash & F_Config --> FB_Cloud
```

---

## 3. Sequence Diagram luồng nghiệp vụ hoàn chỉnh (Báo cáo điểm danh $\rightarrow$ Xuất PDF $\rightarrow$ Upload Firebase Storage)

```mermaid
sequenceDiagram
    autonumber
    actor Lecturer as Giảng viên
    participant View as AttendanceReportScreen (05.02)
    participant VM as ReportViewModel
    participant Storage as FirebaseStorageService
    participant Analytics as FirebaseAnalyticsService
    participant Cloud as Firebase Cloud Storage

    Lecturer->>View: Bấm "Xuất báo cáo PDF lên Firebase Cloud Storage"
    View->>VM: exportPdfAndUploadToCloudStorage()
    activate VM
    VM->>Storage: generateAttendancePdf(subjectCode, className, students)
    activate Storage
    Storage-->>VM: pdfBytes (Uint8List)
    deactivate Storage
    
    VM->>Storage: uploadReportPdf(uid, filename, pdfBytes, onProgress)
    activate Storage
    Storage->>Cloud: putData(pdfBytes, metadata)
    Cloud-->>Storage: uploadTask snapshot progress (0% -> 100%)
    Storage-->>VM: downloadUrl
    deactivate Storage

    VM->>Analytics: logExportReport(classCode, attendedCount, totalCount)
    VM-->>View: notifyListeners() (Cập nhật downloadUrl & Thông báo thành công)
    deactivate VM
    View-->>Lecturer: Hiển thị URL tải và thông báo SnackBar
```

---

## 4. Bảng ánh xạ ViewModel và các Service được Inject

| Tên ViewModel | Các Service được tiêm phụ thuộc (Injected Services) | Trách nhiệm chính |
|---|---|---|
| `AuthViewModel` | `FirebaseAuthService`, `FirebaseAnalyticsService` | Quản lý phiên đăng nhập Google, định tuyến auth state, xóa dữ liệu đệm khi đăng xuất |
| `DashboardViewModel` | `ClassRepository`, `FirebaseRemoteConfigService`, `FirebaseAnalyticsService` | Lấy dữ liệu tiết hôm nay, tiết sắp tới, tự động đồng bộ theo chu kỳ Remote Config |
| `ClassViewModel` | `ClassRepository`, `FirebaseAnalyticsService` | Quản lý danh sách lớp (03.01), chi tiết lớp (03.02), tìm kiếm và quy trình nhập từ Sheet 3 bước (03.03) |
| `ScheduleViewModel` | `ClassRepository`, `FirebaseAnalyticsService` | Quản lý lịch tuần (04.01), xếp lịch mới (04.02), chi tiết trước giờ điểm danh (04.03) |
| `LiveAttendanceViewModel` | `ClassRepository`, `FirebaseCrashlyticsService`, `FirebaseAnalyticsService` | Bộ đếm thời gian QR (45s), thống kê thời gian thực 4 ô, lọc danh sách SV, chốt vắng (04.04) |
| `ReportViewModel` | `ClassRepository`, `FirebaseStorageService`, `FirebaseAuthService`, `FirebaseAnalyticsService` | Báo cáo điểm danh (05.02), chỉnh sửa trạng thái điểm danh, xuất PDF lên Cloud Storage |
| `FirebaseDemoViewModel` | Cả 6 dịch vụ Firebase (`Auth`, `Storage`, `FCM`, `Analytics`, `Crashlytics`, `RemoteConfig`) | Phục vụ trình diễn và chấm điểm trực tiếp toàn bộ 6 dịch vụ đám mây theo yêu cầu Lab 3 |
