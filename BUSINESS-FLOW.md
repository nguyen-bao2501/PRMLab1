# Luồng nghiệp vụ quản lý giảng dạy và điểm danh

## 1. Thiết lập lớp học
- Giảng viên đăng nhập, chọn **Tạo lớp học**.
- Nhập mã lớp, mã môn và chọn học kỳ (SP/SU/FA theo năm hoặc học kỳ đã có).
- Nhập danh sách sinh viên từ Google Sheet trong chi tiết lớp.
- Một lớp là một nhóm sinh viên học một môn trong một học kỳ; sĩ số lấy từ danh sách ghi danh.

## 2. Xếp lịch
- Chọn **Xếp lịch tiết học**, chọn lớp/học kỳ, ngày, slot và phòng.
- Lưu tạo tiết `SCHEDULED`, chưa tạo QR và chưa ghi nhận vắng.
- Không cho xếp vào thời điểm đã qua; kiểm tra trùng giờ giảng viên với lịch đã có.
- Slot 1: 07:00–09:15; slot 2: 09:30–11:45; slot 3: 12:30–14:45; slot 4: 15:00–17:15. Slot 5 và 6 là khung bổ sung 17:30 và 20:00, mỗi slot 135 phút.

## 3. Ba tab chính
1. **Tổng quan**: tiết hôm nay, tiết đang điểm danh, các tiết sắp tới và thao tác tạo lớp/xếp lịch.
2. **Lịch dạy**: bảng tuần, cột thứ 2 đến chủ nhật, hàng slot. Chọn tuần, lọc học kỳ, nhấn ô tiết để xem đúng lớp/phòng và điểm danh.
3. **Tiết học**: chọn lớp, xem tổng quan khóa học và danh sách tiết; nhấn tiết xem chi tiết hoặc điểm danh.

**Lớp học của tôi** là khu vực quản lý khóa học: lọc học kỳ và tìm lớp/môn. Bấm Mở lớp để xem sĩ số, thống kê vắng, danh sách tiết và nhập sinh viên.

## 4. Điểm danh
- Với tiết chưa mở, hộp chi tiết hiển thị lớp, môn, phòng, slot và sĩ số.
- **Mở điểm danh** chỉ khả dụng từ giờ bắt đầu đến trước khi hết 135 phút; backend kiểm tra lại giờ và quyền sở hữu.
- `SCHEDULED → OPEN`: tạo QR. Sinh viên đã ghi danh quét QR; một sinh viên có tối đa một bản ghi trong tiết.
- Khi mở, người chưa quét là **chưa điểm danh**, chưa phải vắng.
- `OPEN → CLOSED`: giảng viên kết thúc hoặc QR hết hạn theo cơ chế có sẵn. Hệ thống ghi vắng cho sinh viên chưa điểm danh.
- Tiết đã đóng không mở lại. Tiết lên lịch nhưng không được mở vẫn chưa có kết quả, không tự tính cả lớp vắng.
- Màn chi tiết hiển thị sĩ số, có mặt/đi muộn, vắng và danh sách điểm danh.

## 5. Thống kê khóa học
- Chỉ lấy bản ghi của tiết `CLOSED`, không tính lịch tương lai, tiết đang mở hay đã hủy.
- Tỷ lệ vắng lớp = số bản ghi ABSENT / tổng bản ghi điểm danh của các tiết đã đóng × 100.
- Xếp hạng 5 sinh viên có số tiết vắng cao nhất; hiển thị số vắng / số tiết có bản ghi và phần trăm.
- PRESENT, LATE và EXCUSED không tính là ABSENT. Nếu chưa có bản ghi, hiển thị chưa có dữ liệu.
- Mẫu số dùng lịch sử bản ghi thực tế, không nhân sĩ số hiện tại với số tiết, tránh sai khi danh sách sinh viên thay đổi.

## 6. Đồng bộ
- Tổng quan/lịch tuần có nút **Đồng bộ** và công tắc tự tải lại lịch mỗi 30 giây.
- Phiên điểm danh đang mở tiếp tục nhận cập nhật từ backend mỗi 5 giây.
- Nút đồng bộ ở thanh trên tải lại danh sách lớp, tiết của lớp đang chọn và chi tiết điểm danh.
- Đồng bộ hiển thị ở đây là tải dữ liệu backend; nhập roster từ Sheet và xuất điểm danh ra Sheet vẫn là các thao tác riêng đã có.

## API mới và triển khai
- `POST /v1/sessions/schedule`: classId, room, startTime (UTC).
- `POST /v1/sessions/{id}/open`: mở tiết đã lên lịch trong khung giờ, chỉ chủ lớp được phép; khóa bản ghi khi mở để tránh hai yêu cầu cùng tạo QR.
- Giữ API tạo phiên tức thời cũ để tương thích, nhưng các nút tạo mới trên giao diện chuyển sang xếp lịch.
- Khởi động lại backend và build lại Flutter sau cập nhật. Database phải cho phép trạng thái `SCHEDULED` trong cột `sessions.status`; cấu hình hiện tại dùng Hibernate ddl-auto=update. Với database cũ có CHECK constraint cố định, cần cập nhật constraint khi triển khai.
- Thời gian lưu UTC, giao diện theo giờ máy; dùng múi giờ Việt Nam trên máy giảng viên. sessionDate của tiết lên lịch được tính theo Asia/Ho_Chi_Minh.
- Ảnh giảng viên là dữ liệu lịch thực tế. Dùng Đọc lịch từ ảnh để nhận diện và kiểm tra trước khi nhập; không tự tạo kết quả điểm danh. Xem OCR-SCHEDULE.md.
- Có xếp từng tiết và nhập cả tuần từ ảnh OCR. Chưa tự lặp lịch cho toàn học kỳ.
