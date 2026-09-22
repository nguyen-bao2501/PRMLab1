# Điểm danh bằng camera điện thoại

## Luồng

Giảng viên nhập danh sách sinh viên từ Sheet (đúng email Google và MSSV), mở buổi học rồi hiển thị QR. Sinh viên dùng camera quét QR → mở trang web → đăng nhập Google → xem form họ tên/MSSV/email → bấm Xác nhận điểm danh. Backend xác thực Google, kiểm tra sinh viên trong lớp, buổi học đang mở và QR còn hạn rồi lưu bản ghi. Bảng giảng viên cập nhật theo chu kỳ 5 giây. Không nhập email tùy ý, không tạo tài khoản giảng viên qua trang điểm danh.

## Cấu hình một lần

1. Đưa backend lên một địa chỉ HTTPS truy cập được từ điện thoại, hoặc dùng HTTPS tunnel về cổng 8080 để demo. Không dùng localhost của máy tính trong QR: localhost trên điện thoại là chính điện thoại. Tunnel phải phục vụ cả trang web và các API của backend. Không public profile dev; tắt profile này khi đưa backend ra Internet vì API dev cấp quyền không cần Google.
2. Trong Google Cloud → Google Auth Platform → Clients, tạo OAuth client loại **Web application**. Thêm origin HTTPS của backend vào **Authorized JavaScript origins**, ví dụ `https://attendance.example.com` (không kèm đường dẫn). Đặt Audience là External. Trang dùng nút Google dạng popup nên không cần khai báo redirect URI cho trang check-in. Client Desktop đã có tiếp tục phục vụ ứng dụng Windows; không dùng client secret của Web trong JavaScript.
3. Dừng backend đang chạy. Trong PowerShell tại thư mục dự án:

```powershell
$env:SPRING_PROFILES_ACTIVE='prod'
.\run-backend-google.ps1 -PublicBaseUrl 'https://TEN-MIEN-CUA-BAN' -WebClientId 'WEB_CLIENT_ID.apps.googleusercontent.com'
```

Hai tham số này tương ứng biến môi trường `ATTENDANCE_PUBLIC_BASE_URL` và `GOOGLE_WEB_CLIENT_ID`. Cần truyền lại khi mở terminal mới. Giữ SQL Server và các cấu hình backend khác như hiện tại. Nếu đổi địa chỉ tunnel, cập nhật origin Google và PublicBaseUrl rồi khởi động lại backend.

4. Mở bản Windows mới. Tạo buổi học hoặc bấm **Làm mới QR** để lấy link mới. Khi chưa đặt PublicBaseUrl, app sẽ báo chưa có link điểm danh thay vì hiển thị token không mở được trên camera.
5. Truy cập `https://TEN-MIEN-CUA-BAN/check-in.html` từ điện thoại để kiểm tra kết nối (trang không có token sẽ nhắc quét QR). Sau đó quét QR đang hiển thị và thử với email thực sự có trong lớp.

## Kiểm tra thực tế

- Email trong roster: form hiển thị đúng danh tính, xác nhận trả về thành công, bảng giảng viên tăng một bản ghi.
- Xác nhận lần hai: báo đã điểm danh; email ngoài lớp: bị từ chối.
- QR hết hạn hoặc phiên đóng: không ghi nhận điểm danh.
- Backend khởi động lại: token QR trong bộ nhớ cũ không còn dùng được, cần làm mới QR.

Chưa có HTTPS và Web Client ID thì chưa thể hoàn tất thử nghiệm Google từ điện thoại. Có thể kiểm tra giao diện ở localhost; để Google hoạt động tại localhost cần thêm origin localhost vào Web client.

Google hướng dẫn: https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid
