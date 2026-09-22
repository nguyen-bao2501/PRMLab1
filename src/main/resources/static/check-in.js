'use strict';
const message = document.getElementById('message');
const confirmButton = document.getElementById('confirm');
const switchButton = document.getElementById('switch');
const googleButton = document.getElementById('google-button');
const identity = document.getElementById('identity');
// The fragment is not sent to the server or in the Referer header.
const token = new URLSearchParams(location.hash.slice(1)).get('token');
let credential = null;
function show(text, kind = '') { message.textContent = text; message.className = kind; }
async function api(path, body) {
  const response = await fetch(`v1/public/attendance/${path}`, {
    method: body ? 'POST' : 'GET', cache: 'no-store',
    headers: body ? {'Content-Type': 'application/json'} : {},
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(20000),
  });
  const data = await response.json();
  if (!response.ok || !data.success) throw new Error(data.message || 'Yêu cầu thất bại.');
  return data.data;
}
identity.onsubmit = async event => {
  event.preventDefault();
  if (!credential || confirmButton.disabled) return;
  confirmButton.disabled = true;
  switchButton.disabled = true;
  show('Đang ghi nhận điểm danh…');
  try {
    const attendance = await api('check-in', {idToken: credential, qrToken: token});
    show(`Điểm danh thành công! ${attendance.studentName || ''} (${attendance.email}) — Buổi #${attendance.sessionId}.`, 'success');
    credential = null;
    confirmButton.hidden = switchButton.hidden = true;
    history.replaceState(null, '', location.pathname);
  } catch (error) {
    show(error.message || 'Không kết nối được máy chủ. Vui lòng thử lại.', 'error');
    confirmButton.disabled = false;
  } finally { switchButton.disabled = false; }
};
switchButton.onclick = () => {
  credential = null;
  google.accounts.id.disableAutoSelect();
  googleButton.hidden = false;
  confirmButton.hidden = switchButton.hidden = identity.hidden = true;
  show('Chọn lại tài khoản Google trong danh sách lớp.');
};
async function init() {
  if (!token || !/^[a-f0-9]{32}$/.test(token)) {
    show('Đường dẫn QR không hợp lệ. Hãy quét mã đang hiển thị của giảng viên.', 'error');
    return;
  }
  try {
    const config = await api('config');
    if (!config.clientId) throw new Error('Trang điểm danh chưa được cấu hình Google Web. Vui lòng báo giảng viên.');
    await new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://accounts.google.com/gsi/client';
      script.onload = resolve;
      script.onerror = () => reject(new Error('Không tải được Google. Kiểm tra kết nối và tải lại trang.'));
      document.head.appendChild(script);
    });
    google.accounts.id.initialize({client_id: config.clientId, auto_select: false,
      callback: async response => {
        credential = response.credential;
        if (!credential) return;
        show('Đang lấy thông tin sinh viên…');
        try {
          const profile = await api('identity', {idToken: credential});
          document.getElementById('full-name').value = profile.fullName;
          document.getElementById('student-code').value = profile.studentCode;
          document.getElementById('email').value = profile.email;
          googleButton.hidden = true;
          identity.hidden = confirmButton.hidden = switchButton.hidden = false;
          confirmButton.disabled = false;
          show('Kiểm tra thông tin bên dưới rồi xác nhận điểm danh.');
        } catch (error) {
          credential = null;
          show(error.message || 'Không lấy được thông tin sinh viên.', 'error');
        }
      },
    });
    google.accounts.id.renderButton(googleButton, {theme: 'outline', size: 'large', text: 'signin_with', width: 280});
    show('Đăng nhập Google để tiếp tục.');
  } catch (error) { show(error.message || 'Không kết nối được máy chủ.', 'error'); }
}
init();
