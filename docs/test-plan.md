# PRM393 Lab 3 — Kế hoạch kiểm thử E2E với Google ARTEMIS

## Phạm vi và thiết lập kiểm thử

Điểm khởi chạy Android trong `lib/main.dart` chạy ứng dụng dành cho giảng viên
(`LoginScreen` → `DashboardScreen`). Kế hoạch này kiểm thử ứng dụng và luồng điều
hướng hiện tại, không kiểm thử ứng dụng riêng `lib/mobile/MobileApp` (hiện chưa
được tham chiếu).

Chạy kiểm thử trên máy ảo hoặc thiết bị Android chuyên dụng, bằng tài khoản Google
chỉ dành cho kiểm thử, dự án Firebase độc lập và backend thử nghiệm có dữ liệu tổng
hợp, không chứa thông tin cá nhân. Không lưu thông tin đăng nhập, khóa API, URL
Google Sheet riêng tư hay tên sinh viên trong kho mã nguồn hoặc trong chỉ dẫn cho
ARTEMIS. Tài khoản kiểm thử cần có sẵn trong trình chọn tài khoản Android.

Các bài kiểm thử hồi quy của ARTEMIS sử dụng cấu hình **Flash**. Cấu hình
`ARTEMIS_BASE_URL` trỏ đến ARTEMIS daemon, `ARTEMIS_DEVICE_SERIAL` là mã thiết bị,
và đặt `ARTEMIS_APP_PACKAGE` nếu application ID Android khác `com.example.prm`.
Các bài kiểm thử cần dữ liệu kiểm thử cũng yêu cầu biến môi trường nêu ở điều kiện
tiên quyết. Trình chạy yêu cầu ARTEMIS trả về dữ liệu quan sát dạng JSON rồi kiểm
tra các giá trị đó, thay vì chỉ dựa vào trạng thái hoàn thành tác vụ.

## Các luồng quan trọng và màn hình

| Luồng | Màn hình / điều hướng | Kết quả đầu cuối |
|---|---|---|
| F1 — Xác thực | Đăng nhập → trình chọn tài khoản Google của Android → Dashboard → Firebase Demo / đăng xuất → Đăng nhập | Đăng nhập bằng tài khoản kiểm thử rồi đăng xuất để quay lại màn hình đăng nhập. |
| F2 — Dashboard và điều hướng | Dashboard → ngăn điều hướng → Danh sách lớp học, Lịch dạy tuần, Firebase Demo | Mỗi mục điều hướng chính mở đúng màn hình. |
| F3 — Quản lý lớp học | Dashboard → Danh sách lớp học → tìm kiếm → Chi tiết lớp → Nhập Sheet | Tìm và mở lớp; nhập Sheet kiểm thử, bao gồm cả tình huống Sheet không hợp lệ và khôi phục. |
| F4 — Lịch và điểm danh | Dashboard → Lịch dạy tuần → Chi tiết buổi học → Xếp lịch hoặc Điểm danh trực tiếp → Báo cáo điểm danh | Xem buổi học, tạo hoặc xác nhận buổi kiểm thử, bắt đầu phiên điểm danh đang hoạt động và xem báo cáo. |
| F5 — Dịch vụ đám mây và xuất dữ liệu | Dashboard → Firebase Demo → Remote Config / FCM / Báo cáo điểm danh → xuất và tải PDF lên | Kiểm tra giá trị Remote Config, nhận và mở thông báo thử nghiệm, xuất PDF lên Cloud Storage. |

## Các trường hợp kiểm thử

Mỗi bài kiểm thử phải bắt đầu từ điều kiện tiên quyết được nêu, tự chuẩn bị trạng thái
cần thiết và không phụ thuộc vào thứ tự chạy các bài khác. Chạy mỗi trường hợp ít
nhất ba lần. Cột **Kết quả chạy** chỉ được cập nhật sau khi đã thu thập bằng chứng
thực tế từ thiết bị.

| ID | Luồng | Điều kiện tiên quyết | Các bước — chỉ dẫn ngôn ngữ tự nhiên cho ARTEMIS | Kết quả mong đợi | Loại kiểm thử | Kết quả chạy |
|---|---|---|---|---|---|---|
| TC-01 | F1 | Ứng dụng đã đăng xuất; tài khoản kiểm thử chuyên dụng có sẵn trong trình chọn tài khoản Android. | Bắt đầu khi đã đăng xuất. Mở ứng dụng, đăng nhập bằng tài khoản kiểm thử qua trình chọn tài khoản Google của Android. Báo cáo màn hình cuối và đăng nhập có thành công không. | Dashboard hiển thị; `authenticated` là `true`. | Tương tác gốc Android / Xác thực | Chưa chạy |
| TC-02 | F2 | Ứng dụng đã đăng nhập. | Mở hoặc quay lại Dashboard. Báo cáo tiêu đề đang hiển thị và số buổi học hôm nay dưới dạng số nguyên. | Dashboard hiển thị; số buổi học là số nguyên không âm. | Kiểm thử nhanh | Chưa chạy |
| TC-03 | F2 | Đang ở Dashboard sau khi đăng nhập. | Mở ngăn điều hướng, chọn “Lớp học của tôi” và báo cáo tiêu đề màn hình. | Màn hình Danh sách lớp học hiển thị. | Điều hướng | Chưa chạy |
| TC-04 | F3 | Đã đăng nhập; backend có lớp kiểm thử theo `ARTEMIS_TEST_CLASS_CODE` (mặc định `PRM393`). | Trong Danh sách lớp học, tìm đúng mã lớp đã cấu hình. Báo cáo từ khóa tìm kiếm, số kết quả và một mã môn học khớp. | Có ít nhất một kết quả; mã môn học chứa mã lớp đã cấu hình. | Tìm kiếm / Phân tích | Chưa chạy |
| TC-05 | F3 | Đã đăng nhập và đang ở Danh sách lớp học. | Tìm `ARTEMIS_NO_SUCH_CLASS_938274`. Báo cáo trạng thái rỗng có hiển thị không và số kết quả. | Trạng thái rỗng hiển thị, số kết quả bằng 0; ứng dụng vẫn hoạt động. | Đường dẫn lỗi | Chưa chạy |
| TC-06 | F3 | Đã đăng nhập; lớp kiểm thử tồn tại. | Tìm `ARTEMIS_TEST_CLASS_CODE`, mở lớp khớp và báo cáo mã môn học cùng tên lớp. | Màn hình Chi tiết lớp hiển thị đúng lớp đã chọn. | Chi tiết | Chưa chạy |
| TC-07 | F3 | Đã đăng nhập; lớp kiểm thử liên kết với Google Sheet riêng chứa dữ liệu tổng hợp; đã đặt `ARTEMIS_TEST_SHEET_TAB`. | Mở Nhập Sheet cho lớp kiểm thử, dùng Sheet đã cấu hình nhưng không hiển thị URL. Chọn tab đã cấu hình; nếu dữ liệu tổng hợp đã được nhập thì xác minh, không nhập trùng. Báo cáo tab và số dòng nhập; không nêu tên, mã số hay email sinh viên. | Bước kết quả hiển thị; tab đúng và số dòng nhập là số nguyên dương. | Luồng nghiệp vụ | Chưa chạy |
| TC-08 | F3 | Đã đăng nhập; lớp kiểm thử tồn tại. | Mở Nhập Sheet, nhập URL không hợp lệ rồi thử tải danh sách tab. Báo cáo thông báo lỗi/khôi phục và ứng dụng còn mở không. | Không báo nhập thành công; có lỗi và cách thử lại; ứng dụng không bị đóng hoặc treo. | Nhánh thay thế / Lỗi | Chưa chạy |
| TC-09 | F4 | Đã đăng nhập; backend có ít nhất một buổi học kiểm thử. | Mở “Lịch dạy tuần”, chọn ngày có buổi kiểm thử, mở chi tiết buổi đó. Báo cáo mã môn học, ngày và phòng hiển thị. | Chi tiết khớp với buổi học đã chọn. | Điều hướng / Chi tiết | Chưa chạy |
| TC-10 | F4 | Đã đăng nhập; `ARTEMIS_TEST_SESSION_DATE` là ngày tương lai hợp lệ, `ARTEMIS_TEST_SESSION_ROOM` đã đặt; backend cho phép dùng lại buổi kiểm thử khớp. | Mở “Xếp lịch tiết học”, tạo buổi kiểm thử theo ngày và phòng đã cấu hình; nếu đã có buổi khớp thì xác minh thay vì tạo trùng. Báo cáo ngày, phòng và tiết. | Buổi học được lưu hoặc xác minh với đúng ngày và phòng. | Luồng nghiệp vụ | Chưa chạy |
| TC-11 | F4 | Đã đăng nhập; biểu mẫu xếp lịch dùng được. | Mở “Xếp lịch tiết học”, nhập ngày trong quá khứ rồi gửi. Báo cáo thông báo kiểm tra dữ liệu và buổi học có được tạo không. | Không lưu buổi không hợp lệ; ứng dụng hiển thị thông báo phù hợp. | Kiểm tra dữ liệu / Lỗi | Chưa chạy |
| TC-12 | F4 | Đã đăng nhập; backend có phiên điểm danh kiểm thử đang hoạt động. | Mở màn hình điểm danh của phiên đang hoạt động. Báo cáo mã môn học, mã QR có hiển thị không và tổng số sinh viên. Không quét hoặc gửi mã QR. | Màn hình Điểm danh trực tiếp hiển thị phiên kiểm thử và mã QR. | Thao tác chính | Chưa chạy |
| TC-13 | F4 | Đã đăng nhập; có dữ liệu báo cáo kiểm thử. | Mở Báo cáo điểm danh, ghi nhận tổng số và số có mặt, chọn bộ lọc “Có mặt”. Báo cáo hàng phù hợp có hiển thị không; không nêu thông tin sinh viên. | Báo cáo và bộ lọc hoạt động; số liệu là số nguyên không âm. | Báo cáo / Bộ lọc | Chưa chạy |
| TC-14 | F5 | Đã đăng nhập; Firebase Storage được cấu hình cho người dùng kiểm thử và có dữ liệu báo cáo. | Mở Báo cáo điểm danh, xuất PDF lên Cloud Storage. Báo cáo tải lên thành công không, đường dẫn lưu trữ và kích thước PDF; không trả về URL tải xuống. | Tải lên thành công; PDF có kích thước dương và đường dẫn bắt đầu bằng `reports/`. | Xuất / Tải lên | Chưa chạy |
| TC-15 | F5 | Đã đăng nhập; tham số Remote Config đã phát hành; `ARTEMIS_EXPECTED_OCR_ENABLED` và `ARTEMIS_EXPECTED_SYNC_INTERVAL` chứa giá trị mong đợi. | Mở Firebase Demo, chọn “Fetch & Activate từ Console”. Báo cáo trạng thái OCR và khoảng thời gian đồng bộ đang hiển thị. | Hai giá trị trên ứng dụng khớp với cấu hình mong đợi, không cần tạo bản build mới. | Cấu hình từ xa | Chưa chạy |
| TC-16 | F5 | Đã đăng nhập; quyền thông báo Android đã cấp hoặc có thể xử lý hộp thoại cấp quyền. Trước mỗi lần chạy, gửi thông báo thử nghiệm từ Firebase Console với tiêu đề `ARTEMIS lab test`. | Nếu hộp thoại quyền Android xuất hiện, xử lý hộp thoại. Nhận thông báo thử nghiệm, mở từ khay thông báo và báo cáo tiêu đề cùng màn hình đích. | Nhận được thông báo; chạm mở thông báo sẽ đưa đến màn hình liên quan. | Tương tác gốc Android / FCM | Chưa chạy |
| TC-17 | F1 | Đã đăng nhập bằng tài khoản kiểm thử. | Mở Firebase Demo, chọn đăng xuất và xác nhận. Báo cáo màn hình cuối cùng và trạng thái xác thực. | Màn hình Đăng nhập hiển thị; `authenticated` là `false`. | Xác thực | Chưa chạy |
| TC-18 | F3 | Đã đăng nhập; có ADB và bật chế độ ghi nhật ký gỡ lỗi Firebase Analytics. | Trong Danh sách lớp học, tìm `ARTEMIS_TEST_CLASS_CODE`. Báo cáo số kết quả và tên sự kiện Analytics `search` nếu quan sát thấy trong nhật ký `FA` của thiết bị. | Có kết quả tìm kiếm; nhật ký thiết bị ghi nhận sự kiện Firebase `search`. | Phân tích / Nhật ký thiết bị | Chưa chạy |

## Chạy lặp và lưu bằng chứng

Chạy mỗi trường hợp ít nhất ba lần bằng `uv run pytest --count=3`. Đặt lại dữ liệu
kiểm thử riêng trước mỗi lần lặp nếu thao tác tạo hoặc nhập dữ liệu. Gửi thông báo
FCM mới từ Firebase Console trước mỗi lần chạy lại TC-16. Không dùng tài khoản cá
nhân.

Với mỗi lượt chạy, lưu kết quả pytest/JUnit, mã trace ARTEMIS và ảnh chụp hoặc bản
phát lại do daemon tạo. Sau khi chạy, điền một dòng cho mỗi trường hợp:

| ID kiểm thử | Số lần chạy | Tỷ lệ đạt | Thời gian trung bình (giây) | Mã trace / bằng chứng | Nguyên nhân và cách khắc phục nếu chập chờn, thất bại hoặc bỏ qua |
|---|---:|---:|---:|---|---|
| Chưa chạy trên thiết bị | — | — | — | — | — |

Nếu một bài kiểm thử không đạt ở bất kỳ lượt nào, hãy xác định nguyên nhân thuộc
ứng dụng, thời gian chờ, dữ liệu kiểm thử hay chỉ dẫn chưa rõ. Ghi lại cách sửa rồi
chạy lại đủ ba lần. Không ghi nhận bài kiểm thử chập chờn là đạt.

## Phiên khám phá bằng cấu hình Pro

Thực hiện một phiên khám phá tự do, không theo kịch bản, trong **15–30 phút** bằng
ARTEMIS **Pro** trên môi trường kiểm thử riêng. Ghi ngày, thiết bị, thời lượng, mã
trace, màn hình/luồng đã khám phá, từng vấn đề phát hiện (hoặc ghi rõ không phát
hiện vấn đề), các bước tái hiện, mức độ nghiêm trọng và hướng xử lý. Phiên khám phá
không thay thế các bài kiểm thử hồi quy bằng Flash ở trên.

### Trạng thái xác minh trước khi chạy thực tế — 06/11/2026

Đợt thử ban đầu với trace `9ee0c772-e3a1-4a71-89ab-c4df073185d5` bị dừng trước khi
mở app. Sau đó Flutter SDK sạch đã được dùng để build APK debug, `uv` environment
được tái tạo và APK `com.example.prm` đã được cài lên `emulator-5554`. Phần báo cáo
ngay sau đây thay thế trạng thái bị chặn của đợt thử ban đầu bằng bằng chứng chạy
thực tế trên thiết bị.

## Báo cáo thực thi ARTEMIS — 06/11/2026

### Môi trường và bằng chứng

- Thiết bị: Android Emulator `Pixel_6`, serial `emulator-5554`, Android 14.
- Ứng dụng: `com.example.prm`, APK debug được build và cài lại trước khi chạy.
- ARTEMIS: helper accessibility và device probe hoạt động; regression dùng Flash,
  exploratory dùng Pro.
- Lệnh chuẩn để chạy lại suite: `Set-Location e2e_test; uv run pytest --count=3 --junitxml=artifacts/junit.xml`.
- Trace/screenshot/replay được ARTEMIS lưu dưới `D:\PRM323\artemis\traces\<trace-id>`.

### Regression đã chạy 3 lần: smoke tiền đăng nhập

Chỉ ca dưới đây được tính pass rate vì không cần tài khoản Google hoặc dữ liệu backend.
Mỗi lượt buộc app về màn hình Login, yêu cầu ARTEMIS trả JSON quan sát và kiểm tra ba
giá trị `screen`, `title_visible`, `button_accessibility_label`; không chỉ dựa vào
trạng thái `SUCCESS`.

| ID | Ca kiểm thử / giá trị quan sát | Trace hợp lệ | Thời gian | Kết quả |
|---|---|---|---:|---|
| TC-SMOKE-01 / run 1 | Login; `Đăng nhập`; label `Đăng nhập bằng Google` | `3e76ee84-9e3e-42a1-916c-afb9ee617a6b` | 30.4s | Pass |
| TC-SMOKE-01 / run 2 | Login; `Đăng nhập`; label `Đăng nhập bằng Google` | `b8b54bca-23f4-44ec-8ce6-37b6901e5456` | 27.2s | Pass |
| TC-SMOKE-01 / run 3 | Login; `Đăng nhập`; label `Đăng nhập bằng Google` | `d4a9710f-e90b-49ef-9e86-7d0f22b24088` | 25.1s | Pass |

**Pass rate:** 3/3 (100%); **thời gian trung bình:** 27.6s. Kết quả JSON của mỗi
trace là `{"observed":{"screen":"Login","title_visible":true,
"google_sign_in_button_visible":true,"button_accessibility_label":"Đăng nhập bằng Google"}}`.

Lượt `08bbcd68-4df1-4417-ab98-c7c108884eee` không được đưa vào tỷ lệ vì emulator
đã tắt sau phiên Pro (ARTEMIS chẩn đoán: ADB không còn liệt kê `emulator-5554`). Đây
là gián đoạn hạ tầng, không phải kết quả app; emulator được boot lại, APK được cài
lại và ba lượt hợp lệ ở trên mới được tính.

### Phiên khám phá Pro

- Trace: `e27c515a-9980-47f1-bb8f-4e89ef5ea7c3`.
- Thời lượng được ARTEMIS ghi nhận: **15 phút 01 giây** (901 giây), 11 vòng khám phá.
- Phạm vi đã kiểm thử: splash/login, dialog quyền notification Android, gọi và hủy
  Google Sign-In gốc, back/home/recents/cold restore, landscape, offline/recovery,
  font scale 1.5, dark/light mode, debounce double-tap, keyboard/D-pad và display zoom.
- Ổn định: không có crash/ANR trong phiên; app khôi phục về Login sau `am kill`.
- Giới hạn: không nhập/chọn tài khoản Google thử nghiệm nên các TC sau đăng nhập
  (lớp học, lịch, điểm danh, báo cáo/export, Remote Config và analytics) vẫn **chưa
  chạy**, không được tính đạt.

| Vấn đề | Mức độ | Bước tái hiện ngắn | Kết quả quan sát / xử lý đề nghị |
|---|---|---|---|
| Font scale 1.5 gây RenderFlex overflow | Medium | Đặt `font_scale=1.5`, mở Login | Footer overflow 57px; dùng `Flexible`/`Expanded` và cho Text wrap. |
| Cắt layout ở landscape | Medium | Xoay Login ngang | Footer/divider bị cắt; bảo đảm scroll/fit cho viewport ngang. |
| Lỗi mạng bị báo là người dùng hủy | Low | Tắt Wi-Fi/data, bấm Google login, quay lại | Snackbar báo hủy; phân biệt lỗi mạng để hướng dẫn retry. |
| Logo thiếu content description | Low | Kiểm tra accessibility tree | Thêm semantic label `Logo FPT Education`. |
| Nhãn FPT UNIVERSITY hiển thị trùng | Low | Mở Login | Giữ một brand label thống nhất. |

Kết quả chi tiết do Pro tạo: `D:\PRM323\artemis\traces\e27c515a-9980-47f1-bb8f-4e89ef5ea7c3\notes\output.md`.
Trước khi nộp, cần thêm dedicated Google test account và synthetic Firebase/backend
fixture, rồi chạy đủ TC-01…TC-18 ba lần và cập nhật bảng này bằng JUnit/trace thực tế.

### Xác thực tài khoản vai trò backend — 06/11/2026

Hai tài khoản test được xác thực qua `POST /v1/dev/login`. Với access token chỉ giữ
trong bộ nhớ của phiên chạy, `GET /v1/auth/me` trả đúng email và role cho cả hai
trường hợp: `TEACHER` và `STUDENT` (2/2 pass). Token và thông tin đăng nhập không
được ghi vào repository hay báo cáo.

Đây là kiểm tra precondition của backend, không phải kết quả E2E ARTEMIS. Luồng
dev-login đã được thêm cho bản Flutter **debug**: chỉ khi `kDebugMode`, Login hiển thị
`Email kiểm thử`, `Vai trò kiểm thử` và `Đăng nhập thử nghiệm`; token chỉ được giữ
trong bộ nhớ và bị xóa khi sign-out. Bản release không có luồng này.

Hai test độc lập `TC19` (Teacher) và `TC20` (Student) được thêm vào
`e2e_test/test_auth.py`; email lấy từ biến môi trường
`ARTEMIS_TEST_TEACHER_EMAIL` / `ARTEMIS_TEST_STUDENT_EMAIL`, không được lưu vào repo.
`uv run pytest --collect-only -q` đã thu thập thành công **20** test.

### Lần chạy role UI bị hạ tầng chặn — 06/11/2026

ARTEMIS đã xác minh accessibility tree của panel debug qua trace
`d2bf23bf-21bb-4882-8498-b94a75288469`: panel, nhãn email, selector role và submit
button đều hiện đúng. Hai lần sau (`4b6ae1cd-2db5-472c-9c46-2156c42f51c8`,
`8b4d6610-59a3-492b-bc10-7ecf63e00618`) và lần retry
`4943db01-a3dc-4e05-8584-01fa29ed6201` không được tính pass/fail: emulator tự biến
mất khỏi ADB khi ARTEMIS đang chạy (screenshot trống/hierarchy rỗng). ARTEMIS diagnosis
đã khởi động lại ADB, reboot Pixel_6, reset UIAutomator và device probe từng trở về
`ready`, nhưng lỗi lặp lại ở lần chạy UI kế tiếp. Do vậy **TC19/TC20 chưa có pass rate**;
không được ghi nhận là đạt cho tới khi emulator ổn định và mỗi ca chạy 3/3 lần.

Lần thử lại sau khi thiết bị được báo sẵn sàng (trace
`36ce408c-8438-4254-be76-ba31cc18527d`) cũng không được tính: Android hiển thị
`System UI isn't responding`, sau đó splash của app đứng ở màn hình xanh. ARTEMIS đã
cho phép notification và launch lại app nhưng không thể đến Login. Đây là ANR của
emulator/System UI trước bước xác thực ứng dụng, không phải pass/fail của TC19.
