# FPT Attendance — Windows desktop

Giao diện Flutter dành cho giảng viên, dùng trực tiếp Spring Boot trong repository. Dữ liệu trên giao diện lấy từ API; không có dữ liệu giả trong ứng dụng. Ảnh ở `build/previews` được tạo bằng fixture của bài kiểm thử, chỉ để kiểm tra bố cục.

## Chạy

1. Khởi động backend với SQL Server/Redis/Google service account theo cấu hình hiện tại.
2. Cài Flutter và Visual Studio với workload Desktop development with C++. Không cần plugin trình duyệt hoặc bật Developer Mode.
3. Chạy:

```powershell
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

Mã backend hiện tại không cấu hình context path `/api`. App tự thêm `/v1` vào API_BASE_URL. Nếu triển khai sau reverse proxy có `/api`, dùng `http://host:port/api`. Có thể thay địa chỉ ngay ở mục **Cấu hình kết nối** trên màn hình đăng nhập.

Nhấn **Đăng nhập với devtest** để vào trực tiếp bằng `devtest@gmail.com`, vai trò `TEACHER`, không cần Google hay mật khẩu. Nút này gọi `POST /v1/dev/login`, sau đó lấy thông tin tài khoản và lớp học bằng JWT backend cấp. Endpoint yêu cầu Spring profile `dev` (repository hiện đã cấu hình profile này). Google là lựa chọn đăng nhập phụ.

Trong debug, mục **Đăng nhập dành cho developer** vẫn cho phép đổi email và vai trò để kiểm thử tài khoản khác; email mặc định là `devtest@gmail.com`. Mục tùy chỉnh này chỉ xuất hiện ở release khi truyền `--dart-define=ENABLE_DEV_LOGIN=true`.

## Google OAuth cho desktop

Tạo OAuth client loại **Desktop app** trong Google Cloud. Backend xác minh audience của Google ID token nên `GOOGLE_CLIENT_ID` của backend phải trùng client ID desktop. Không thể dùng nguyên client ID web/Android làm desktop loopback client.

```powershell
flutter run -d windows --dart-define=GOOGLE_DESKTOP_CLIENT_ID=YOUR_DESKTOP_CLIENT_ID --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=YOUR_DESKTOP_CLIENT_SECRET
```

Ứng dụng mở trình duyệt hệ thống, dùng Authorization Code + PKCE, kiểm tra state, nhận callback tại loopback `127.0.0.1` với cổng ngẫu nhiên, rồi gửi ID token đến `POST /v1/auth/google`. Client secret ở đây là thông tin client **installed app** theo cấu hình Google, không phải service-account private key hay web-client secret. Không đưa file service account vào Flutter.

Nguồn: https://developers.google.com/identity/protocols/oauth2/native-app

JWT chỉ được giữ trong bộ nhớ và gửi bằng `Authorization: Bearer`. Sau khi đóng ứng dụng cần đăng nhập lại. HTTP 401 đưa người dùng về màn hình đăng nhập. Backend vẫn quyết định vai trò và quyền truy cập.

## Luồng sử dụng

- **Lớp học của tôi** → Tạo lớp (mã lớp, mã môn, học kỳ) → Mở lớp.
- **Nhập từ Google Sheet** → dán URL/ID spreadsheet → chọn tab. Backend cần có quyền đọc file.
- **Tạo buổi học** → nhập phòng → QR thật từ `qrToken` hiển thị trong màn hình Điểm danh.
- Danh sách điểm danh được tải lại mỗi 5 giây khi phiên đang mở. Tìm theo tên/MSSV/email, lọc Có mặt/Đi muộn/Vắng/Có phép.
- **Làm mới QR** gọi endpoint refresh; không tự kéo dài phiên. Countdown dùng `qrExpiresAt`. Khi mở lại một phiên, GET không trả QR token nên nhấn Làm mới QR để cấp mã mới.
- **Trình chiếu mã QR** mở giao diện lớn, cập nhật trạng thái/hết hạn. **Kết thúc điểm danh** đóng phiên và backend đánh dấu vắng.
- **Báo cáo** → chọn lớp/buổi → Xuất báo cáo Google Sheet. Backend hiện ghi đè cột F của tab đã nhập, trả URL Google Sheet; không trả file Excel/CSV. Giao diện nêu rõ thao tác này trước khi xuất.
- Nếu đăng nhập bằng vai trò STUDENT, ứng dụng hiện màn hình nhập QR token và lịch sử cá nhân. Sinh viên có thể dùng ứng dụng mobile để quét QR; desktop không truy cập camera.

## API được kết nối

| Nhóm | Endpoint |
| --- | --- |
| Auth | POST `/v1/auth/google`, GET `/v1/auth/me`, POST `/v1/dev/login` |
| Class | POST/GET `/v1/classes`, GET/DELETE `/v1/classes/{id}` |
| Sheet | GET `/v1/classes/sheet-tabs?spreadsheetId=...`, POST `/v1/classes/{id}/import-sheet` |
| Session | POST `/v1/sessions`, GET `/v1/sessions?classId=...`, GET `/v1/sessions/{id}`, POST `/v1/sessions/{id}/refresh-qr`, POST `/v1/sessions/{id}/close` |
| Attendance | GET `/v1/attendances?sessionId=...`, POST `/v1/attendances/check-in`, GET `/v1/attendances/me` |
| Export | POST `/v1/exports/session/{sessionId}` |

Tất cả response được đọc theo envelope `success/message/data`. UI xử lý timeout, lỗi kết nối, lỗi backend, trạng thái rỗng và khóa thao tác khi đang gửi request. Tổng có mặt đếm PRESENT/LATE, không dùng `checkedIn` vì backend đếm cả bản ghi ABSENT sau khi đóng phiên. Backend chưa có endpoint roster chi tiết; bảng chỉ hiển thị các bản ghi do `/attendances` trả về.

Hai sửa lỗi backend đi kèm: bỏ lớp `isActive=false` khỏi danh sách, cập nhật `qrExpiresAt` khi refresh để lịch tự đóng dùng thời hạn mới.

## Kiểm tra

```powershell
flutter analyze lib test
flutter test --no-pub
.\mvnw.cmd -Dtest=DesktopWorkflowTest test
flutter build windows --debug
```

Các bài kiểm thử xác minh contract endpoint/payload/query/Bearer, lỗi API/401, phân quyền sinh viên, giữ token khi polling, đóng phiên, đếm có mặt, lọc bảng, QR hết hạn và bố cục desktop. Widget tests tạo ảnh login/attendance trong `build/previews`.


## Nhập tất cả lớp từ một Google Sheet

Vào **Lớp học của tôi** hoặc **Buổi học** → **Nhập tất cả lớp từ Sheet**. Dán đường dẫn/ID file → **Lấy tất cả lớp từ Sheet** → xem danh sách tất cả tab → **Chọn tất cả** (hoặc chỉ chọn tab lớp học) → **Nhập N lớp đã chọn**. Không cần tạo từng lớp trước. Link người dùng cung cấp đã được điền sẵn trong hộp thoại; có thể đổi sang file khác.

Mỗi tab là một lớp riêng, mã lớp trong hệ thống dùng toàn bộ tên tab (ví dụ `11_PRN232_SE1917` và `12_PRM393_SE1917`). Nhờ vậy hai môn của cùng SE1917 không bị gộp, không cần thay đổi ràng buộc unique class_code hiện có. Backend lấy mã môn từ tên tab; tab không nhận diện được vẫn xuất hiện và có thể nhập mã môn thủ công trước khi chọn. Có thể nhập học kỳ cho các lớp mới.

Ứng dụng gọi các API hiện có: lấy tab, lấy danh sách lớp, tạo lớp còn thiếu, rồi import từng tab. Khi nhập lại cùng spreadsheet + tab, dùng lại lớp đã liên kết. Không ghi đè mapping của một file khác chỉ vì trùng tên tab. Tab lỗi được báo riêng, tab khác tiếp tục; nút thử lại chỉ chọn các tab lỗi. Nếu tạo lớp thành công nhưng import thất bại, lần sau dùng lại lớp trống đó. Dòng sinh viên đã ghi danh do backend bỏ qua.

**Khởi động lại backend sau khi cập nhật mã:** `ClassResponse` nay trả thêm `spreadsheetId` để nhận diện chính xác mapping khi nhập lại. Sau khi cập nhật app, đóng/mở lại ứng dụng Windows. Không cần xóa lớp đã tạo thủ công; chúng vẫn tồn tại độc lập cho tới khi bạn chủ động xóa.
