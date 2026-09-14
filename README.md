

## 🏗 Kiến trúc

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENTS (Flutter)                         │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  Desktop App     │         │   Mobile App     │         │
│  │  (GV)            │         │   (HS)           │         │
│  │  - Show QR       │         │  - Scan QR       │         │
│  │  - Realtime list │         │  - Login Google  │         │
│  └────────┬─────────┘         └────────┬─────────┘         │
└───────────┼────────────────────────────┼───────────────────┘
            │       HTTPS / REST         │
            └────────────┬───────────────┘
                         ▼
            ┌────────────────────────┐
            │   SPRING BOOT BACKEND  │
            │  Controllers/Services  │
            │  Repositories          │
            └───────────┬────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   ┌─────────┐   ┌──────────┐   ┌─────────────┐
   │SQL      │   │QR Token  │   │ Google APIs │
   │Server   │   │Store     │   │ (OAuth +    │
   │(PRM)    │   │(memory/  │   │  Sheets)    │
   │         │   │ Redis)   │   │             │
   └─────────┘   └──────────┘   └─────────────┘
```

---

## 🔄 Luồng nghiệp vụ

### Luồng 1: Import danh sách lớp (đầu kỳ — 1 lần)

```
GV (Desktop)                    Backend                    Google Sheet
    │                              │                            │
    │──1. GET /sheet-tabs─────────►│                            │
    │                              │──list tabs────────────────►│
    │                              │◄─[11_PRN232_SE1917,...]────│
    │◄─[tabs + parsed code]────────│                            │
    │                              │                            │
    │──2. POST /classes (tạo lớp)─►│                            │
    │◄─classId─────────────────────│                            │
    │                              │                            │
    │──3. POST /import-sheet──────►│                            │
    │                              │──read A2:E────────────────►│
    │                              │◄─[rows]────────────────────│
    │                              │──save users + enrollments──┤
    │                              │──save class_sheets mapping─┤
    │◄─{rowsImported: 25}──────────│                            │
```

### Luồng 2: Điểm danh (mỗi buổi)

```
GV (Desktop)              HS (Mobile)              Backend
    │                          │                       │
    │──1. POST /sessions───────┼──────────────────────►│
    │                          │                       │──generate QR token
    │◄─{sessionId, qrToken}────┼───────────────────────│
    │                          │                       │
    │   [Hiển thị QR]          │                       │
    │                          │                       │
    │                          │──2. Scan QR───────────│
    │                          │──3. Login Google──────│
    │                          │──4. POST /check-in───►│
    │                          │                       │──resolve token
    │                          │                       │──check roster
    │                          │                       │──save attendance
    │                          │◄─{success}────────────│
    │                          │                       │
    │──5. GET /attendances─────┼──────────────────────►│
    │◄─[{students...}]─────────┼───────────────────────│
```

### Luồng 3: Export báo cáo (cuối buổi)

```
GV (Desktop)                    Backend                    Google Sheet
    │                              │                            │
    │──1. POST /sessions/{id}/close►│                            │
    │                              │                            │
    │──2. POST /exports/session/{id}►│                           │
    │                              │──load enrollments──────────┤
    │                              │──load attendances──────────┤
    │                              │──build email→"A"/"AS"──────┤
    │                              │──write column F───────────►│
    │◄─{spreadsheetUrl}────────────│                            │
```

### Luồng 4: Refresh QR (Desktop tự động mỗi 5 phút)

```
Desktop                         Backend
   │                              │
   │──POST /refresh-qr───────────►│
   │                              │──generate token mới
   │◄─{qrToken, qrExpiresAt}──────│
   │                              │
   │  [Refresh UI QR]             │
```

---

## 🔐 Authentication

### Hai lớp bảo vệ

```
Request → [1] SecurityFilterChain (JWT) → [2] @PreAuthorize (Role) → Controller
```

### Google OAuth 2.0 Flow

```
Client (Flutter)              Google OAuth              Backend
     │                             │                       │
     │──1. Login Google───────────►│                       │
     │◄─id_token───────────────────│                       │
     │                                                     │
     │──2. POST /auth/google {idToken}────────────────────►│
     │                             │                       │──verify id_token
     │                             │                       │──find/create user
     │                             │                       │──generate JWT
     │◄─{accessToken (JWT)}────────────────────────────────│
     │                                                     │
     │──3. Request với Authorization: Bearer <JWT>────────►
```

### JWT Structure

```json
{
  "sub": "1",
  "email": "teacher@example.com",
  "role": "TEACHER",
  "iat": 1726000000,
  "exp": 1726086400
}
```

### Dev Login (chỉ dev)

```
POST /v1/dev/login
Body: { "email": "devtest@gmail.com", "role": "TEACHER" }
```

---

## 📡 API Reference

### Tổng hợp Endpoints

| # | Method | Endpoint | Role | Mô tả |
|---|---|---|---|---|
| 1 | POST | `/v1/auth/google` | Public | Login Google |
| 2 | GET | `/v1/auth/me` | Auth | Info user hiện tại |
| 3 | POST | `/v1/dev/login` | Public (dev) | Login nhanh cho dev |
| 4 | GET | `/v1/dev/whoami` | Auth | Check JWT hiện tại |
| 5 | POST | `/v1/classes` | TEACHER | Tạo lớp |
| 6 | GET | `/v1/classes` | TEACHER | DS lớp của GV |
| 7 | GET | `/v1/classes/{id}` | TEACHER | Chi tiết lớp |
| 8 | DELETE | `/v1/classes/{id}` | TEACHER | Vô hiệu hóa lớp |
| 9 | GET | `/v1/classes/sheet-tabs` | TEACHER | DS tab Sheet |
| 10 | POST | `/v1/classes/{id}/import-sheet` | TEACHER | Import roster |
| 11 | POST | `/v1/sessions` | TEACHER | Tạo buổi + QR |
| 12 | POST | `/v1/sessions/{id}/refresh-qr` | TEACHER | Refresh QR |
| 13 | POST | `/v1/sessions/{id}/close` | TEACHER | Đóng buổi |
| 14 | GET | `/v1/sessions?classId=` | TEACHER | DS buổi của lớp |
| 15 | GET | `/v1/sessions/{id}` | TEACHER | Chi tiết buổi |
| 16 | POST | `/v1/attendances/check-in` | STUDENT | HS check-in |
| 17 | GET | `/v1/attendances?sessionId=` | TEACHER | DS đã điểm danh |
| 18 | GET | `/v1/attendances/me` | STUDENT | Lịch sử của HS |
| 19 | POST | `/v1/exports/session/{id}` | TEACHER | Xuất Sheet |

---

### 1. POST `/v1/auth/google`

**Request:**
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "studentCode": null
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Đăng nhập thành công",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86400,
    "user": {
      "id": 5,
      "email": "hs@fpt.edu.vn",
      "fullName": "Nguyễn Văn A",
      "role": "STUDENT"
    }
  }
}
```

---

### 3. POST `/v1/dev/login`

**Request:**
```json
{
  "email": "devtest@gmail.com",
  "role": "TEACHER"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Dev login thành công",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 86400,
    "user": {
      "id": 1,
      "email": "devtest@gmail.com",
      "fullName": "Dev TEACHER",
      "role": "TEACHER"
    }
  }
}
```

---

### 5. POST `/v1/classes`

**Header:** `Authorization: Bearer <JWT_TEACHER>`

**Request:**
```json
{
  "classCode": "SE1917",
  "className": "Lập trình Java - SE1917",
  "subjectCode": "PRN232",
  "semester": "SU2026"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Tạo lớp thành công",
  "data": {
    "id": 1,
    "classCode": "SE1917",
    "subjectCode": "PRN232",
    "className": "Lập trình Java - SE1917",
    "semester": "SU2026",
    "studentCount": 0,
    "sheetName": null,
    "createdAt": "2026-09-14T12:00:00Z"
  }
}
```

---

### 9. GET `/v1/classes/sheet-tabs`

**Header:** `Authorization: Bearer <JWT_TEACHER>`

**Query:** `?spreadsheetId=1Uewi8TJPsTFedaeVz8IybvB2HbeHIfDFB-R9o2s9LyI`

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "sheetName": "11_PRN232_SE1917",
      "subjectCode": "PRN232",
      "classCode": "SE1917"
    },
    {
      "sheetName": "12_PRM393_SE1917",
      "subjectCode": "PRM393",
      "classCode": "SE1917"
    }
  ]
}
```

---

### 10. POST `/v1/classes/{id}/import-sheet`

**Header:** `Authorization: Bearer <JWT_TEACHER>`

**Request:**
```json
{
  "spreadsheetId": "1Uewi8TJPsTFedaeVz8IybvB2HbeHIfDFB-R9o2s9LyI",
  "sheetName": "11_PRN232_SE1917"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Import '11_PRN232_SE1917': 25 thêm mới, 3 bỏ qua",
  "data": {
    "classId": 1,
    "spreadsheetId": "1Uewi8TJPsTFedaeVz8IybvB2HbeHIfDFB-R9o2s9LyI",
    "sheetName": "11_PRN232_SE1917",
    "subjectCode": "PRN232",
    "classCodeFromTab": "SE1917",
    "rowsImported": 25,
    "rowsSkipped": 3,
    "totalInSheet": 28
  }
}
```

---

### 11. POST `/v1/sessions`

**Header:** `Authorization: Bearer <JWT_TEACHER>`

**Request:**
```json
{
  "classId": 1,
  "room": "A101",
  "startTime": "2026-09-14T12:00:00Z"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Tạo buổi điểm danh thành công",
  "data": {
    "id": 3,
    "classId": 1,
    "classCode": "SE1917",
    "subjectCode": "PRN232",
    "className": "Lập trình Java",
    "sessionDate": "2026-09-14",
    "startTime": "2026-09-14T12:00:00Z",
    "endTime": null,
    "room": "A101",
    "status": "OPEN",
    "qrToken": "a359e30658994e769ee3015999ff10ff",
    "qrExpiresAt": "2026-09-14T12:10:00Z",
    "totalStudents": 28,
    "checkedIn": 0
  }
}
```

---

### 12. POST `/v1/sessions/{id}/refresh-qr`

**Header:** `Authorization: Bearer <JWT_TEACHER>`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 3,
    "qrToken": "b8f2c1a4d3e5f6g7h8i9j0k1l2m3n4o5",
    "qrExpiresAt": "2026-09-14T12:20:00Z",
    "status": "OPEN"
  }
}
```

---

### 16. POST `/v1/attendances/check-in`

**Header:** `Authorization: Bearer <JWT_STUDENT>`

**Request:**
```json
{
  "qrToken": "a359e30658994e769ee3015999ff10ff",
  "latitude": 10.8411,
  "longitude": 106.8098,
  "deviceInfo": "iPhone 15"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Điểm danh thành công",
  "data": {
    "id": 1,
    "sessionId": 3,
    "studentId": 5,
    "studentName": "Nguyễn Ngọc Bảo Cường",
    "studentCode": "SE193416",
    "email": "firephoenix0304@gmail.com",
    "status": "PRESENT",
    "markCode": "A",
    "checkInTime": "2026-09-14T12:05:15Z",
    "ipAddress": "127.0.0.1"
  }
}
```

---

### 19. POST `/v1/exports/session/{id}`

**Header:** `Authorization: Bearer <JWT_TEACHER>`

**Response 200:**
```json
{
  "success": true,
  "message": "Xuất điểm danh thành công",
  "data": {
    "sessionId": 3,
    "spreadsheetId": "1Uewi8TJPsTFedaeVz8IybvB2HbeHIfDFB-R9o2s9LyI",
    "sheetName": "11_PRN232_SE1917",
    "spreadsheetUrl": "https://docs.google.com/spreadsheets/d/1Uewi8TJPsTFedaeVz8IybvB2HbeHIfDFB-R9o2s9LyI/edit",
    "presentCount": 22,
    "absentCount": 6,
    "totalStudents": 28
  }
}
```

---

## 📦 Data Models

### User

```json
{
  "id": 5,
  "googleId": "118234567890123456789",
  "email": "hs@fpt.edu.vn",
  "fullName": "Nguyễn Văn A",
  "avatarUrl": "https://...",
  "studentCode": "SE193416",
  "role": "STUDENT",
  "isActive": true,
  "createdAt": "2026-09-14T12:00:00Z"
}
```

**Roles:** `STUDENT` | `TEACHER` | `ADMIN`

### ClassRoom

```json
{
  "id": 1,
  "classCode": "SE1917",
  "subjectCode": "PRN232",
  "className": "Lập trình Java",
  "semester": "SU2026",
  "teacherId": 1,
  "totalSessions": 5,
  "isActive": true,
  "sheetName": "11_PRN232_SE1917"
}
```

### Session

```json
{
  "id": 3,
  "classId": 1,
  "sessionDate": "2026-09-14",
  "startTime": "2026-09-14T12:00:00Z",
  "endTime": "2026-09-14T12:15:00Z",
  "room": "A101",
  "status": "OPEN"
}
```

**Status:** `OPEN` | `CLOSED` | `CANCELLED`

### Attendance

```json
{
  "id": 1,
  "sessionId": 3,
  "studentId": 5,
  "status": "PRESENT",
  "markCode": "A",
  "source": "APP",
  "checkInTime": "2026-09-14T12:05:15Z",
  "ipAddress": "127.0.0.1",
  "latitude": 10.8411,
  "longitude": 106.8098
}
```

**Status:** `PRESENT` | `LATE` | `ABSENT` | `EXCUSED`
**MarkCode:** `A` (có mặt) | `AS` (vắng)

### Google Sheet Format

| Cột | Trường | Ví dụ |
|---|---|---|
| A | Class | SE1917 |
| B | RollNumber | SE193416 |
| C | Email | hs@fpt.edu.vn |
| D | MemberCode | Nguyễn Văn A |
| E | FullName | Nguyễn Văn A |
| F | **Điểm danh** | **A / AS** |


```json
{
  "success": false,
  "message": "Email/MSSV không có trong danh sách lớp",
  "errors": {
    "code": "NOT_IN_ROSTER"
  },
  "timestamp": 1726000000000
}
```

---


### Truy cập

| URL | Mô tả |
|---|---|
| `http://localhost:8080/api/swagger-ui.html` | Swagger UI |
| `http://localhost:8080/api/v3/api-docs` | OpenAPI JSON |
| `http://localhost:8080/api/actuator/health` | Health check |

---

## 🧪 Test nhanh

### Script test full flow

```bash
#!/bin/bash
BASE=http://localhost:8080/api/v1

# 1. Login GV
TEACHER_TOKEN=$(curl -s -X POST $BASE/dev/login \
  -H "Content-Type: application/json" \
  -d '{"email":"devtest@gmail.com","role":"TEACHER"}' \
  | jq -r '.data.accessToken')

# 2. Tạo lớp
curl -X POST $BASE/classes \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "classCode": "SE1917",
    "className": "Lớp SE1917",
    "subjectCode": "PRN232",
    "semester": "SU2026"
  }'

# 3. Load sheet tabs
curl "$BASE/classes/sheet-tabs?spreadsheetId=1Uewi8TJPsTFedaeVz8IybvB2HbeHIfDFB-R9o2s9LyI" \
  -H "Authorization: Bearer $TEACHER_TOKEN"

# 4. Import
curl -X POST $BASE/classes/1/import-sheet \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "spreadsheetId": "1Uewi8TJPsTFedaeVz8IybvB2HbeHIfDFB-R9o2s9LyI",
    "sheetName": "11_PRN232_SE1917"
  }'

# 5. Tạo session
SESSION=$(curl -s -X POST $BASE/sessions \
  -H "Authorization: Bearer $TEACHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"classId": 1, "room": "A101"}')
QR_TOKEN=$(echo $SESSION | jq -r '.data.qrToken')
SESSION_ID=$(echo $SESSION | jq -r '.data.id')

# 6. Login HS
STUDENT_TOKEN=$(curl -s -X POST $BASE/dev/login \
  -H "Content-Type: application/json" \
  -d '{"email":"firephoenix0304@gmail.com","role":"STUDENT"}' \
  | jq -r '.data.accessToken')

# 7. Check-in
curl -X POST $BASE/attendances/check-in \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"qrToken\":\"$QR_TOKEN\"}"

# 8. Xuất Sheet
curl -X POST $BASE/exports/session/$SESSION_ID \
  -H "Authorization: Bearer $TEACHER_TOKEN"
```


