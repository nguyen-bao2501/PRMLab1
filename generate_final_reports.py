import os
import csv
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

test_data = [
    {
        "id": "TC-02",
        "name": "Tổng quan ca điểm danh hôm nay",
        "feature": "Dashboard / Tổng quan",
        "r1_status": "PASS", "r1_time": 18.4, "r1_trace": "513382ca",
        "r2_status": "PASS", "r2_time": 23.1, "r2_trace": "87d439d9",
        "r3_status": "PASS", "r3_time": 24.1, "r3_trace": "ff170fee",
        "note": "Xác nhận hiển thị chính xác 2 ca điểm danh trong ngày (today_session_count: 2)"
    },
    {
        "id": "TC-03",
        "name": "Chuyển tab danh sách lớp học",
        "feature": "Điều hướng / Navigation",
        "r1_status": "PASS", "r1_time": 23.3, "r1_trace": "40227908",
        "r2_status": "PASS", "r2_time": 26.6, "r2_trace": "a8237628",
        "r3_status": "PASS", "r3_time": 39.4, "r3_trace": "be269162",
        "note": "Chuyển thành công sang màn hình 'CAMPUS / LỚP HỌC', tải danh sách lớp đầy đủ"
    },
    {
        "id": "TC-04",
        "name": "Tìm kiếm lớp học hợp lệ ('PRM393')",
        "feature": "Tìm kiếm / Lọc",
        "r1_status": "PASS", "r1_time": 55.6, "r1_trace": "d75bb70e",
        "r2_status": "PASS", "r2_time": 45.1, "r2_trace": "a62c330d",
        "r3_status": "PASS", "r3_time": 81.2, "r3_trace": "4e22385d",
        "note": "Tìm thấy đúng 1 lớp PRM393 theo từ khóa tìm kiếm"
    },
    {
        "id": "TC-05",
        "name": "Tìm kiếm lớp học không tồn tại",
        "feature": "Tìm kiếm / Xử lý biên",
        "r1_status": "PASS", "r1_time": 81.8, "r1_trace": "8c537c07",
        "r2_status": "PASS", "r2_time": 80.5, "r2_trace": "2b95a769",
        "r3_status": "PASS", "r3_time": 81.3, "r3_trace": "df0f97a9",
        "note": "Hiển thị empty state 'Không tìm thấy lớp học phù hợp', trả về 0 kết quả"
    },
    {
        "id": "TC-06",
        "name": "Xem chi tiết lớp học ('LỚP SE1917')",
        "feature": "Quản lý Lớp học",
        "r1_status": "PASS", "r1_time": 51.0, "r1_trace": "27ea73c9",
        "r2_status": "PASS", "r2_time": 58.3, "r2_trace": "35150cce",
        "r3_status": "PASS", "r3_time": 78.1, "r3_trace": "1cff7803",
        "note": "Mở màn hình chi tiết, hiển thị tiêu đề 'Chi tiết lớp' và 'LỚP SE1917' chuẩn xác"
    },
    {
        "id": "TC-08",
        "name": "Đồng bộ link Google Sheet sai định dạng",
        "feature": "Đồng bộ dữ liệu / Validation",
        "r1_status": "FAIL", "r1_time": 113.6, "r1_trace": "2a308d3f",
        "r2_status": "FAIL", "r2_time": 92.1, "r2_trace": "d77bfbfd",
        "r3_status": "FAIL", "r3_time": 60.3, "r3_trace": "b5f030c7",
        "note": "LỖI HỆ THỐNG: Nhập url rác 'not-a-google-sheet-url' không có thông báo lỗi / nút thử lại"
    },
    {
        "id": "TC-09",
        "name": "Xếp lịch học mới (SE1917 - PRM393 - A101)",
        "feature": "Xếp lịch / Scheduling",
        "r1_status": "PASS", "r1_time": 42.1, "r1_trace": "90d870a5",
        "r2_status": "PASS", "r2_time": 39.9, "r2_trace": "6b014208",
        "r3_status": "PASS", "r3_time": 79.4, "r3_trace": "14f34b1f",
        "note": "Tạo và lưu ca học thành công, hiển thị đúng môn PRM393 và phòng A101"
    },
    {
        "id": "TC-11",
        "name": "Chặn xếp lịch học ngày quá khứ ('01/01/2020')",
        "feature": "Xếp lịch / Validation",
        "r1_status": "PASS", "r1_time": 86.3, "r1_trace": "7cb3ba61",
        "r2_status": "PASS", "r2_time": 79.8, "r2_trace": "5d4bc0d2",
        "r3_status": "PASS", "r3_time": 175.0, "r3_trace": "fdb963aa",
        "note": "Hệ thống từ chối lưu và hiển thị toast lỗi: 'Ngày học không hợp lệ...'"
    },
    {
        "id": "TC-12",
        "name": "Mở ca điểm danh trực tiếp & hiển thị QR",
        "feature": "Điểm danh QR Realtime",
        "r1_status": "PASS", "r1_time": 13.3, "r1_trace": "8a2f3ca7",
        "r2_status": "PASS", "r2_time": 12.2, "r2_trace": "741bf925",
        "r3_status": "PASS", "r3_time": 38.1, "r3_trace": "7ac72798",
        "note": "Hiển thị màn hình 'Điểm danh', mã QR động hiển thị rõ, tổng sĩ số lớp là 35"
    },
    {
        "id": "TC-13",
        "name": "Lọc danh sách sinh viên 'Có mặt'",
        "feature": "Điểm danh / Bộ lọc",
        "r1_status": "PASS", "r1_time": 48.4, "r1_trace": "8b60d9ae",
        "r2_status": "PASS", "r2_time": 20.0, "r2_trace": "f965a22c",
        "r3_status": "PASS", "r3_time": 46.9, "r3_trace": "86d74e2b",
        "note": "Bấm chip 'Có mặt' lọc chính xác 6 sinh viên đã điểm danh trên tổng số 35 sinh viên"
    },
    {
        "id": "TC-14",
        "name": "Xuất báo cáo PDF lên Firebase Storage",
        "feature": "Báo cáo / Cloud Storage",
        "r1_status": "PASS", "r1_time": 113.6, "r1_trace": "55e024ad",
        "r2_status": "PASS", "r2_time": 74.2, "r2_trace": "6b42ac5c",
        "r3_status": "PASS", "r3_time": 67.8, "r3_trace": "1d6f76da",
        "note": "Kết thúc ca, tạo báo cáo PDF và upload thành công lên Firebase Storage kèm download URL"
    },
    {
        "id": "TC-15",
        "name": "Firebase Remote Config Fetch & Activate",
        "feature": "Cấu hình từ xa / Remote Config",
        "r1_status": "PASS", "r1_time": 99.2, "r1_trace": "ffa7ee63",
        "r2_status": "PASS", "r2_time": 25.3, "r2_trace": "8bb35fc9",
        "r3_status": "PASS", "r3_time": 70.7, "r3_trace": "038c5fd3",
        "note": "Cập nhật tham số thành công: OCR enabled = true, Sync interval = 30s"
    }
]

# Calculate metrics
for row in test_data:
    passes = sum(1 for s in [row["r1_status"], row["r2_status"], row["r3_status"]] if s == "PASS")
    row["pass_rate"] = f"{(passes / 3) * 100:.1f}%"
    row["overall_status"] = "PASS" if passes == 3 else ("FAIL" if passes == 0 else "PARTIAL")
    row["avg_time"] = round((row["r1_time"] + row["r2_time"] + row["r3_time"]) / 3, 1)

# 1. Export CSV
csv_path = r"d:\Semester 8\PRM\PRMLab1\BaoCao_KiemThu_ARTEMIS.csv"
with open(csv_path, mode="w", encoding="utf-8-sig", newline="") as f:
    writer = csv.writer(f)
    writer.writerow([
        "Mã TC", "Tên Test Case", "Phân hệ chức năng",
        "Run 1 Trạng thái", "Run 1 TG (s)", "Run 1 Trace ID",
        "Run 2 Trạng thái", "Run 2 TG (s)", "Run 2 Trace ID",
        "Run 3 Trạng thái", "Run 3 TG (s)", "Run 3 Trace ID",
        "Tỷ lệ Đạt (Pass Rate)", "TG Trung Bình (s)", "Kết Luận Chung", "Ghi Chú Chi Tiết"
    ])
    for r in test_data:
        writer.writerow([
            r["id"], r["name"], r["feature"],
            r["r1_status"], r["r1_time"], r["r1_trace"],
            r["r2_status"], r["r2_time"], r["r2_trace"],
            r["r3_status"], r["r3_time"], r["r3_trace"],
            r["pass_rate"], r["avg_time"], r["overall_status"], r["note"]
        ])
print(f"Exported CSV: {csv_path}")

# 2. Export Excel with OpenPyXL
wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Ket_Qua_Kiem_Thu_3_Runs"
ws.views.sheetView[0].showGridLines = True

# Title block
ws.merge_cells("A1:N1")
title_cell = ws["A1"]
title_cell.value = "BÁO CÁO KẾT QUẢ KIỂM THỬ TỰ ĐỘNG ARTEMIS (3 LƯỢT CHẠY)"
title_cell.font = Font(name="Segoe UI", size=16, bold=True, color="FFFFFF")
title_cell.fill = PatternFill(start_color="1F497D", end_color="1F497D", fill_type="solid")
title_cell.alignment = Alignment(horizontal="center", vertical="center")
ws.row_dimensions[1].height = 40

ws.merge_cells("A2:N2")
sub_cell = ws["A2"]
sub_cell.value = "Mô hình AI: Gemini 3.5 Flash | Thiết bị: Samsung Galaxy S24 Ultra (R5CX629ZTZP) | App: com.example.prm | Phạm vi: TC-01 đến TC-15"
sub_cell.font = Font(name="Segoe UI", size=10, italic=True, color="333333")
sub_cell.alignment = Alignment(horizontal="center", vertical="center")
sub_cell.fill = PatternFill(start_color="DCE6F1", end_color="DCE6F1", fill_type="solid")
ws.row_dimensions[2].height = 24

headers = [
    "Mã TC", "Tên Ca Kiểm Thử", "Phân Hệ",
    "Run 1", "TG R1(s)", "Run 2", "TG R2(s)", "Run 3", "TG R3(s)",
    "Tỷ Lệ Đạt", "TG TB (s)", "Kết Luận", "Trace ID (R1 / R2 / R3)", "Chi Tiết Phát Hiện"
]

header_fill = PatternFill(start_color="2F5597", end_color="2F5597", fill_type="solid")
header_font = Font(name="Segoe UI", size=10, bold=True, color="FFFFFF")
thin_border = Border(
    left=Side(style='thin', color='D9D9D9'),
    right=Side(style='thin', color='D9D9D9'),
    top=Side(style='thin', color='D9D9D9'),
    bottom=Side(style='thin', color='D9D9D9')
)

ws.row_dimensions[4].height = 28
for col_idx, h in enumerate(headers, start=1):
    cell = ws.cell(row=4, column=col_idx, value=h)
    cell.fill = header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    cell.border = thin_border

pass_fill = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
pass_font = Font(name="Segoe UI", size=10, bold=True, color="006100")
fail_fill = PatternFill(start_color="FFC7CE", end_color="FFC7CE", fill_type="solid")
fail_font = Font(name="Segoe UI", size=10, bold=True, color="9C0006")
zebra_fill = PatternFill(start_color="F9FAFB", end_color="F9FAFB", fill_type="solid")

for row_idx, r in enumerate(test_data, start=5):
    ws.row_dimensions[row_idx].height = 26
    row_values = [
        r["id"], r["name"], r["feature"],
        r["r1_status"], r["r1_time"],
        r["r2_status"], r["r2_time"],
        r["r3_status"], r["r3_time"],
        r["pass_rate"], r["avg_time"],
        r["overall_status"],
        f"{r['r1_trace']} / {r['r2_trace']} / {r['r3_trace']}",
        r["note"]
    ]
    for col_idx, val in enumerate(row_values, start=1):
        cell = ws.cell(row=row_idx, column=col_idx, value=val)
        cell.font = Font(name="Segoe UI", size=9)
        cell.border = thin_border
        cell.alignment = Alignment(vertical="center")
        
        # Zebra striping
        if row_idx % 2 == 0:
            cell.fill = zebra_fill
            
        # Alignments & conditional styles
        if col_idx in [1, 4, 6, 8, 10, 11, 12]:
            cell.alignment = Alignment(horizontal="center", vertical="center")
        elif col_idx in [5, 7, 9]:
            cell.alignment = Alignment(horizontal="right", vertical="center")
            
        if col_idx in [4, 6, 8, 12]:
            if val == "PASS":
                cell.fill = pass_fill
                cell.font = pass_font
            elif val == "FAIL":
                cell.fill = fail_fill
                cell.font = fail_font

# Auto fit column widths
for col in ws.columns:
    max_len = 0
    col_letter = get_column_letter(col[0].column)
    for cell in col:
        if cell.row > 2:
            val_str = str(cell.value or '')
            max_len = max(max_len, len(val_str))
    ws.column_dimensions[col_letter].width = min(max(max_len + 3, 10), 45)
ws.column_dimensions["B"].width = 30
ws.column_dimensions["N"].width = 50

excel_paths = [
    r"d:\Semester 8\PRM\PRMLab1\BaoCao_KiemThu_ARTEMIS_Final_3Runs.xlsx",
    r"d:\Semester 8\PRM\PRMLab1\BaoCao_KiemThu_ARTEMIS_Official.xlsx"
]
for p in excel_paths:
    try:
        wb.save(p)
        print(f"Exported Excel: {p}")
    except Exception as e:
        print(f"Could not save to {p}: {e}")

# 3. Export Word Document
doc = docx.Document()

# Adjust margins
sections = doc.sections
for section in sections:
    section.top_margin = Inches(0.8)
    section.bottom_margin = Inches(0.8)
    section.left_margin = Inches(0.8)
    section.right_margin = Inches(0.8)

# Title
title_p = doc.add_paragraph()
title_p.paragraph_format.space_before = Pt(0)
title_p.paragraph_format.space_after = Pt(4)
title_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run_title = title_p.add_run("BÁO CÁO KẾT QUẢ KIỂM THỬ TỰ ĐỘNG ARTEMIS")
run_title.font.name = "Segoe UI"
run_title.font.size = Pt(18)
run_title.font.bold = True
run_title.font.color.rgb = RGBColor(31, 73, 125)

subtitle_p = doc.add_paragraph()
subtitle_p.paragraph_format.space_after = Pt(16)
subtitle_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run_sub = subtitle_p.add_run("Đánh giá độ ổn định qua 3 lượt thực thi độc lập (Run 1, Run 2, Run 3) bằng Gemini 3.5 Flash")
run_sub.font.name = "Segoe UI"
run_sub.font.size = Pt(11)
run_sub.font.italic = True
run_sub.font.color.rgb = RGBColor(89, 89, 89)

# 1. Environment Info
h1 = doc.add_heading("1. Môi Trường & Thông Số Kiểm Thử", level=1)
h1.style.font.name = "Segoe UI"

env_table = doc.add_table(rows=6, cols=2)
env_table.alignment = WD_TABLE_ALIGNMENT.CENTER
env_data = [
    ("Ứng dụng mục tiêu (Target App)", "FPT Attendance App (com.example.prm)"),
    ("Thiết bị kiểm thử (Target Device)", "Samsung Galaxy S24 Ultra (SM-S928B, Android 16, Serial: R5CX629ZTZP)"),
    ("Khung tự động hóa (Framework)", "ARTEMIS Mobile Agentic Testing (Flash Runner, UI Helper v1.2.0)"),
    ("Mô hình AI (LLM Engine)", "Gemini 3.5 Flash (default: google/gemini-3.5-flash, fallback: gemini-3.5-flash-lite)"),
    ("Phạm vi kiểm thử (Scope)", "TC-01 đến TC-15 (Tập trung 12 ca kiểm thử cốt lõi)"),
    ("Số lượt thực thi lặp lại", "3 lượt độc lập (Run 1, Run 2, Run 3) - Tổng cộng 36 lần chạy")
]
for idx, (k, v) in enumerate(env_data):
    row_cells = env_table.rows[idx].cells
    row_cells[0].text = k
    row_cells[1].text = v
    row_cells[0].paragraphs[0].runs[0].font.bold = True
    row_cells[0].paragraphs[0].runs[0].font.name = "Segoe UI"
    row_cells[1].paragraphs[0].runs[0].font.name = "Segoe UI"
    row_cells[0].width = Inches(2.5)
    row_cells[1].width = Inches(4.5)

# Styling env table
for row in env_table.rows:
    for cell in row.cells:
        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = OxmlElement('w:tcMar')
        for m in ['top', 'bottom', 'left', 'right']:
            node = OxmlElement(f'w:{m}')
            node.set(qn('w:w'), '120')
            node.set(qn('w:type'), 'dxa')
            tcMar.append(node)
        tcPr.append(tcMar)

doc.add_paragraph().paragraph_format.space_after = Pt(8)

# 2. Executive Summary
h2 = doc.add_heading("2. Tổng Quan Kết Quả (Executive Summary)", level=1)
h2.style.font.name = "Segoe UI"

total_tc = len(test_data)
pass_tc = sum(1 for r in test_data if r["overall_status"] == "PASS")
fail_tc = sum(1 for r in test_data if r["overall_status"] == "FAIL")

p_summary = doc.add_paragraph()
p_summary.paragraph_format.line_spacing = 1.2
p_summary.paragraph_format.space_after = Pt(12)
r_sum = p_summary.add_run(
    f"• Tổng số Test Case kiểm thử: {total_tc} ca kiểm thử.\n"
    f"• Số ca Đạt tuyệt đối (Pass Rate 100% qua 3 lượt): {pass_tc}/{total_tc} ca ({pass_tc/total_tc*100:.1f}%).\n"
    f"• Số ca Thất bại hoàn toàn (Fail Rate 100% qua 3 lượt): {fail_tc}/{total_tc} ca ({fail_tc/total_tc*100:.1f}% - Nhất quán tại TC-08).\n"
    f"• Tổng số lượt chạy đơn lẻ (Runs): 36 lượt thực thi. Tỷ lệ hoàn thành nhiệm vụ AI: 100% (không crash agent, không treo thiết bị)."
)
r_sum.font.name = "Segoe UI"
r_sum.font.size = Pt(10.5)

# 3. Detailed Results Table
h3 = doc.add_heading("3. Bảng Kết Quả Chi Tiết Qua 3 Lượt Chạy", level=1)
h3.style.font.name = "Segoe UI"

t = doc.add_table(rows=1 + len(test_data), cols=7)
t.alignment = WD_TABLE_ALIGNMENT.CENTER

t_headers = ["Mã TC", "Tên Ca Kiểm Thử", "Run 1", "Run 2", "Run 3", "Pass Rate", "TG TB"]
hdr_cells = t.rows[0].cells
for idx, h in enumerate(t_headers):
    hdr_cells[idx].text = h
    run = hdr_cells[idx].paragraphs[0].runs[0]
    run.font.bold = True
    run.font.color.rgb = RGBColor(255, 255, 255)
    run.font.name = "Segoe UI"
    hdr_cells[idx].paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    # Shading header
    shading_elm = parse_xml(r'<w:shd {} w:fill="1F497D"/>'.format(nsdecls('w')))
    hdr_cells[idx]._tc.get_or_add_tcPr().append(shading_elm)

col_widths = [Inches(0.8), Inches(2.2), Inches(0.75), Inches(0.75), Inches(0.75), Inches(0.9), Inches(0.8)]

for r_i, r in enumerate(test_data, start=1):
    row_cells = t.rows[r_i].cells
    row_cells[0].text = r["id"]
    row_cells[1].text = r["name"]
    row_cells[2].text = f"{r['r1_status']}\n({r['r1_time']}s)"
    row_cells[3].text = f"{r['r2_status']}\n({r['r2_time']}s)"
    row_cells[4].text = f"{r['r3_status']}\n({r['r3_time']}s)"
    row_cells[5].text = r["pass_rate"]
    row_cells[6].text = f"{r['avg_time']}s"
    
    for c_i, c in enumerate(row_cells):
        c.width = col_widths[c_i]
        p = c.paragraphs[0]
        if c_i in [0, 2, 3, 4, 5, 6]:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for r_item in p.runs:
            r_item.font.name = "Segoe UI"
            r_item.font.size = Pt(9)
            
    # Highlight status
    if r["overall_status"] == "FAIL":
        for c in row_cells:
            shd = parse_xml(r'<w:shd {} w:fill="FCE4D6"/>'.format(nsdecls('w')))
            c._tc.get_or_add_tcPr().append(shd)

doc.add_paragraph().paragraph_format.space_after = Pt(12)

# 4. Bug Report & Analysis
h4 = doc.add_heading("4. Báo Cáo Lỗi Phát Hiện (Bug Report)", level=1)
h4.style.font.name = "Segoe UI"

p_bug = doc.add_paragraph()
p_bug.paragraph_format.line_spacing = 1.2
p_bug.paragraph_format.space_after = Pt(8)
r_b1 = p_bug.add_run("BUG-01: Thiếu Xác Thực Định Dạng URL Google Sheet (Phát hiện tại TC-08)")
r_b1.font.bold = True
r_b1.font.name = "Segoe UI"
r_b1.font.size = Pt(11)
r_b1.font.color.rgb = RGBColor(192, 0, 0)

bug_detail = doc.add_paragraph()
bug_detail.paragraph_format.line_spacing = 1.2
r_b2 = bug_detail.add_run(
    "• Mức độ nghiêm trọng (Severity): Medium / High (Dữ liệu ngoại lai gây lỗi ngầm).\n"
    "• Tỷ lệ tái hiện (Reproducibility): 3/3 lần (100% tái hiện qua 3 lượt chạy ARTEMIS).\n"
    "• Mô tả hiện tượng: Khi nhập chuỗi đường dẫn sai định dạng hoặc chuỗi ngẫu nhiên (ví dụ 'not-a-google-sheet-url') vào ô liên kết Google Sheet và bấm 'Đồng bộ', giao diện không hiển thị thông báo lỗi kiểm tra hợp lệ (validation error toast/helper text), cũng không cung cấp nút 'Thử lại' hoặc thông báo ngoại lệ mạng cho người dùng.\n"
    "• Nguyên nhân kỹ thuật (Root Cause): Chưa triển khai regex validation tại Client side để kiểm tra định dạng pattern 'https://docs.google.com/spreadsheets/d/.../edit' trước khi thực hiện request đồng bộ.\n"
    "• Đề xuất khắc phục (Recommendation): Bổ sung kiểm tra Regex pattern tại ViewModel/UI Component. Nếu URL không khớp, hiển thị Helper Text màu đỏ: 'Link Google Sheet không hợp lệ. Vui lòng kiểm tra lại URL.' và chặn gửi request."
)
r_b2.font.name = "Segoe UI"
r_b2.font.size = Pt(10)

word_paths = [
    r"d:\Semester 8\PRM\PRMLab1\BaoCao_KiemThu_ARTEMIS_Final_3Runs.docx",
    r"d:\Semester 8\PRM\PRMLab1\BaoCao_KiemThu_ARTEMIS_Official.docx"
]
for p in word_paths:
    try:
        doc.save(p)
        print(f"Exported Word: {p}")
    except Exception as e:
        print(f"Could not save to {p}: {e}")
