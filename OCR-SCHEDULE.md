# Đọc lịch dạy từ ảnh (Windows)

## Cách dùng
1. Mở **Lịch dạy → Đọc lịch từ ảnh → Chọn ảnh lịch dạy**.
2. Chọn PNG/JPG/BMP rõ chữ, có năm, các ngày trong tuần và nhãn Slot. Dung lượng tối đa 10 MB; kích thước tối đa theo giới hạn Windows OCR (thường 2600 pixel mỗi chiều).
3. Xem ảnh và bảng nhận diện. Sửa mã lớp, môn, phòng, thứ/slot nếu cần; bỏ chọn tiết không muốn nhập.
4. Nhập học kỳ (ảnh không chứa học kỳ), kiểm tra **thứ Hai đầu tuần**. Có thể chọn lại tuần nếu năm/ngày không đọc được. Không tự lặp lịch sang tuần khác.
5. Tích **Tôi đã kiểm tra…**, chọn **Nhập lịch đã kiểm tra**, rồi **Hoàn tất**. Lịch tuần chuyển tới tuần vừa nhập.

Chỉ sau bước 5 mới gọi backend. Lịch cũ vẫn được nhập dưới trạng thái SCHEDULED, không sinh QR hoặc bản ghi có mặt/vắng. Nhập lại cùng lớp–môn–kỳ, thời điểm và phòng sẽ bỏ qua tiết đã có. Trùng thời gian với tiết khác hoặc khác phòng sẽ từ chối toàn bộ lần nhập, không lưu dở một phần.

## Cơ chế
- `assets/scripts/read_schedule_ocr.ps1`: chọn ảnh và gọi Windows.Media.Ocr, xuất chữ cùng tọa độ. Không gửi ảnh ra dịch vụ bên ngoài, không cần API key.
- `lib/services/schedule_ocr.dart`: gọi script đóng gói trong asset qua danh sách tham số, giới hạn thời gian và dọn thư mục tạm.
- `lib/services/schedule_image_parser.dart`: phân tích tọa độ cột ngày/hàng Slot, ghép mã bị OCR tách và chuẩn hóa I/1, O/0 trong phần số. Dành cho bố cục FPT trong ảnh mẫu, không phải mọi dạng thời khóa biểu.
- `lib/screens/import_schedule_image_dialog.dart`: xem trước, sửa, xác nhận và nhập.
- `POST /v1/sessions/import-schedule`: chỉ TEACHER; kiểm tra DTO, khóa giảng viên cho các lượt import, giao dịch nguyên tử và chống nhập trùng. Thời gian slot theo Asia/Ho_Chi_Minh.
- Lớp được phân biệt bằng giảng viên + học kỳ + mã lớp + mã môn, nên SE1917–PRN232 và SE1917–PRM393 là hai lớp môn riêng. Không tự nhập danh sách sinh viên; nhập roster từ Sheet như trước.

## Chạy
Khởi động lại backend bằng `./mvnw.cmd spring-boot:run`; chạy lại ứng dụng bằng `flutter run -d windows` hoặc build `flutter build windows`. Cần full restart/rebuild để đóng gói asset script mới.

Windows phải có **English OCR**: Settings → Time & language → Language & region → English → Language options. Nếu thiếu, ứng dụng hiện thông báo cài thành phần OCR. Script dùng Windows PowerShell 5.1 đi kèm Windows; ExecutionPolicy Bypass chỉ áp dụng cho tiến trình chạy script, không sửa chính sách toàn máy.

## Kiểm chứng với ảnh giảng viên
OCR thực tế của ảnh tuần 07–13/09/2026 được lưu thành fixture chữ/tọa độ (không chứa đường dẫn ảnh cá nhân). Kiểm thử so sánh đủ **20 tiết / 10 nhóm lớp–môn**, từng phòng và cặp ngày thứ 2/5, 3/6, 4/7. Kiểm thử thêm thiếu năm, thiếu phòng, ảnh không có Slot, màn xác nhận và nhập trùng backend.

Nguồn API: [Microsoft — OcrEngine.RecognizeAsync](https://learn.microsoft.com/en-us/uwp/api/windows.media.ocr.ocrengine.recognizeasync).

## Sửa lỗi database cũ khi nhập lịch
Nếu database SQL Server được tạo trước tính năng xếp lịch, CHECK constraint cũ của sessions.status chỉ cho phép OPEN/CLOSED/CANCELLED. Khi lưu SCHEDULED sẽ bị từ chối và giao diện cũ chỉ báo Lỗi hệ thống.
Backend hiện chạy ScheduledStatusMigration lúc khởi động: chỉ mở rộng đúng constraint ba trạng thái cũ, trong transaction, không thay đổi bản ghi; chạy lại an toàn. SQL nằm ở src/main/resources/db/migration/scheduled_status_sqlserver.sql.
OCR không đọc đủ mã lớp/môn sẽ giữ dòng trong bảng nhưng bỏ chọn. Điền thông tin và tích Nhập; hoặc dùng Thêm tiết bị thiếu. Không tự suy đoán lớp từ ngày khác.
