# Google Login Test

Package Flutter độc lập để test `POST /v1/auth/google`. Có thể xoá toàn bộ thư mục này mà không ảnh hưởng backend.

## Chuẩn bị Google Cloud

1. Trong Google Cloud Console, tạo OAuth 2.0 Client ID kiểu **Web application**.
2. Lấy giá trị dạng `...apps.googleusercontent.com`.
3. Đặt chính giá trị đó cho backend: `GOOGLE_CLIENT_ID`.
4. Nếu chạy Android, tạo thêm OAuth client kiểu **Android**, dùng package name `com.prm323.google_login_test` và SHA-1 debug certificate của app. App sẽ dùng Web Client ID ở bước chạy bên dưới để nhận đúng `idToken` cho backend.

## Chạy Android emulator

Từ thư mục này, chạy một lần để tạo host Android/Web nếu chưa có:

```powershell
flutter create --platforms android,web .
flutter pub get
flutter run --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Mặc định API là `http://10.0.2.2:8080` (Android emulator gọi máy host). Nếu API chạy URL khác:

```powershell
flutter run --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Với điện thoại thật, dùng IP LAN của máy chạy backend, không dùng `localhost` hay `10.0.2.2`.

## Chạy Flutter Web

Web bắt buộc phải nhận Web OAuth Client ID lúc khởi tạo. App tự truyền ID này
qua `clientId` trên Web; Android/iOS dùng nó làm `serverClientId` để ID token
có audience phù hợp với backend:

```powershell
flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com --dart-define=API_BASE_URL=http://localhost:8080
```

Trong Google Cloud Console, thêm origin của ứng dụng (ví dụ
`http://localhost:PORT`) vào **Authorized JavaScript origins** của Web OAuth
client. Thay đổi Dart define cần **hot restart** hoặc chạy lại lệnh, không chỉ
hot reload.

Web sử dụng nút Google Identity chính thức thay vì gọi
`GoogleSignIn.signIn()` từ nút Flutter tự tạo. Luồng Web cũ chỉ trả access
token; nút chính thức mới cung cấp `idToken` để backend xác thực.

### Chạy nhanh khi phát triển

Từ thư mục `google_login_test`, dùng một trong hai cách sau:

- Trong VS Code, mở **Run and Debug** và chọn `Google Login Test (Chrome)`,
  sau đó bấm nút chạy.
- Trong PowerShell, chạy `./run-web.ps1`.

Cả hai cách đều dùng cổng `63402` và các Dart define phát triển đã cấu hình
sẵn. Không đưa OAuth client secret vào ứng dụng Flutter.

Không gửi `idToken` lên nơi khác hoặc lưu nó lâu dài; backend sẽ đổi nó thành token đăng nhập của hệ thống.
