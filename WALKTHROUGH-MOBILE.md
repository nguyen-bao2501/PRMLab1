# 📱 Hướng Dẫn & Tài Liệu Phát Triển Flutter Mobile App (FPT Attendance)

Tài liệu này ghi lại chi tiết về kiến trúc, thành phần đã triển khai, cách vận hành và hướng phát triển tiếp theo cho phiên bản **Flutter Mobile App** của ứng dụng điểm danh FPT University.

---

## 🏗 1. Bối cảnh & Kiến trúc tổng thể

- **Backend (Spring Boot / Java)**: Giữ nguyên 100% logic nghiệp vụ. Sử dụng các API có sẵn:
  - `POST /v1/auth/google`: Đăng nhập Google bằng `idToken`, nhận JWT Bearer Token.
  - `POST /v1/dev/login`: Đăng nhập nhanh cho môi trường test/dev.
  - `GET /v1/auth/me`: Lấy thông tin user hiện tại.
  - `POST /v1/attendances/check-in`: Gửi `qrToken` kèm JWT token để điểm danh.
  - `GET /v1/attendances/me`: Lấy lịch sử điểm danh của sinh viên.
- **Desktop App (Flutter Windows)**: Dành cho Giảng viên (tạo lớp, tạo buổi học, hiển thị mã QR tự động refresh 5 phút/lần).
- **Mobile App (Flutter Mobile)**: Dành cho Sinh viên (Đăng nhập Google/Dev, quét QR qua camera, điểm danh, xem lịch sử).

---

## 📂 2. Cấu trúc thư mục Mobile (`lib/mobile/`)

```
lib/
├── mobile/
│   ├── models/
│   │   └── student_attendance.dart        # Model dữ liệu điểm danh & lịch sử
│   ├── services/
│   │   └── mobile_auth_service.dart       # Quản lý xác thực Google, Dev login, JWT, Server URL
│   ├── screens/
│   │   ├── mobile_login_screen.dart       # Đăng nhập Google & Dev Mode & Config API URL
│   │   ├── qr_scanner_screen.dart         # Quét mã QR camera + nhập mã thủ công + kết quả
│   │   ├── attendance_history_screen.dart # Danh sách & thống kê lịch sử điểm danh
│   │   ├── mobile_profile_screen.dart     # Hồ sơ sinh viên, cài đặt máy chủ & đăng xuất
│   │   └── mobile_main_screen.dart        # Thanh điều hướng 3 Tab chính (BottomNavigationBar)
│   └── mobile_app.dart                    # Điều phối luồng khởi động & kiểm tra session
├── main.dart                              # Nhận diện thiết bị (Desktop vs Mobile)
```

---

## 🌟 3. Các màn hình & Tính năng chính

### A. Màn hình Đăng nhập ([mobile_login_screen.dart](file:///d:/Semester%208/PRM/PRMLab1/lib/mobile/screens/mobile_login_screen.dart))
- **Đăng nhập Google**: Sử dụng Google Sign-In chính thức cho sinh viên tài khoản FPT (`@fpt.edu.vn`).
- **Chế độ Dev Login**: Giúp thử nghiệm nhanh với các tài khoản `student1@fpt.edu.vn`, `student2@fpt.edu.vn` mà không lo bị kẹt lỗi Google Cloud SHA-1 fingerprint trên Android Emulator.
- **Cài đặt Server API Base URL**: Cho phép chỉnh sửa URL máy chủ kết nối (ví dụ `http://10.0.2.2:8080`, `http://localhost:8080` hoặc IP Wi-Fi nội bộ `http://192.168.x.x:8080`).

### B. Màn hình Quét QR ([qr_scanner_screen.dart](file:///d:/Semester%208/PRM/PRMLab1/lib/mobile/screens/qr_scanner_screen.dart))
- Sử dụng package `mobile_scanner` tốc độ cao với hiệu ứng laser scanline chuyển động mượt mà.
- Hỗ trợ bật/tắt đèn pin (Flashlight) và lật camera trước/sau.
- Tự động trích xuất mã token hex 32 ký tự hoặc đọc từ link URL (`...#token=abc` hoặc `?token=abc`).
- Nút **Nhập mã điểm danh thủ công** phòng trường hợp camera bị mờ hoặc máy ảo không có camera.
- Hiển thị Bottom Sheet thông báo kết quả điểm danh sinh động (thông tin sinh viên, phòng học, mã lớp, thời gian điểm danh).

### C. Màn hình Lịch sử điểm danh ([attendance_history_screen.dart](file:///d:/Semester%208/PRM/PRMLab1/lib/mobile/screens/attendance_history_screen.dart))
- Thẻ thống kê tổng quan số buổi: **Có mặt (Present)**, **Đi muộn (Late)**, **Vắng mặt (Absent)**.
- Danh sách bản ghi từng buổi học với tên môn/mã lớp, phòng học, thời gian cụ thể, tên thiết bị đã điểm danh.
- Vuốt xuống để làm mới dữ liệu (Pull-to-refresh).

### D. Màn hình Hồ sơ & Cài đặt ([mobile_profile_screen.dart](file:///d:/Semester%208/PRM/PRMLab1/lib/mobile/screens/mobile_profile_screen.dart))
- Thẻ thông tin tài khoản sinh viên (Họ tên, MSSV, Email Google).
- Hướng dẫn các bước điểm danh.
- Quản lý địa chỉ máy chủ và đăng xuất tài khoản.

---

## 🚀 4. Hướng dẫn chạy & Thử nghiệm

### Cách 1: Xem giao diện Mobile trực tiếp trên Windows Desktop
1. Chạy lệnh:
   ```powershell
   flutter run -d windows
   ```
2. Trên góc trên bên phải màn hình Desktop Giảng viên, bấm nút **"📱 Xem Mobile App"**.
3. Bạn có thể thử nghiệm ngay giao diện mobile, quét mã / nhập token, xem lịch sử điểm danh ngay trên Windows!
4. Bấm **"Về giao diện Desktop (GV)"** để quay lại.

### Cách 2: Chạy trên Android Emulator (Máy ảo Pixel 8a)
1. Mở máy ảo Pixel 8a:
   ```powershell
   flutter emulators --launch Pixel_8a
   ```
2. Run app lên máy ảo:
   ```powershell
   flutter run -d Pixel_8a
   ```
3. Mặc định app sẽ tự kết nối tới backend Spring Boot trên máy host qua địa chỉ `http://10.0.2.2:8080`.

### Cách 3: Chạy trên điện thoại Android thật
1. Cắm cáp USB kết nối điện thoại Android (đã bật USB Debugging).
2. Chạy lệnh: `flutter run` và chọn thiết bị điện thoại của bạn.
3. Trong ứng dụng Mobile, mở Cài đặt máy chủ và nhập IP Wi-Fi máy tính của bạn (ví dụ `http://192.168.1.x:8080` hoặc ngrok URL).

---

## 🔮 5. Gợi ý hướng phát triển thêm (Roadmap)

1. **Thông báo đẩy (Push Notifications)**:
   - Tích hợp Firebase Cloud Messaging (FCM) để nhắc nhở sinh viên khi giảng viên vừa mở buổi học mới.
2. **Điểm danh bằng GPS / Geofencing**:
   - Tích hợp vị trí thiết bị để chỉ cho phép điểm danh nếu sinh viên đang thực sự ở trong khuôn viên cơ sở / phòng học.
3. **Lưu Offline / Sync khi mất mạng**:
   - Lưu trữ tạm thời yêu cầu điểm danh trong SQLite/Hive nếu điện thoại rớt mạng và tự động đồng bộ khi có kết nối.
4. **Biểu đồ thống kê học tập (Analytics Dashboard)**:
   - Hiển thị biểu đồ tỉ lệ đi học qua các tuần/học kỳ giúp sinh viên chủ động theo dõi nguy cơ bị cấm thi (vắng quá 20%).
