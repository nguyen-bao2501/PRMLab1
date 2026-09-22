"use strict";
const message = document.getElementById("message");
const confirmButton = document.getElementById("confirm");
const switchButton = document.getElementById("switch");
const googleButton = document.getElementById("google-button");
const identity = document.getElementById("identity");
// The fragment is not sent to the server or in the Referer header.
const token = new URLSearchParams(location.hash.slice(1)).get("token");
let credential = null;
function setStep(index) {
  ["step-login", "step-review", "step-done"].forEach((id, i) => {
    const step = document.getElementById(id);
    step.classList.toggle("complete", i < index);
    if (i === index) step.setAttribute("aria-current", "step");
    else step.removeAttribute("aria-current");
  });
  document.getElementById("form-title").textContent = [
    "Chào bạn, sẵn sàng vào lớp?",
    "Thông tin đúng là bạn?",
    "Điểm danh hoàn tất.",
  ][index];
  document.getElementById("form-description").textContent = [
    "Dùng tài khoản Google có trong danh sách lớp để xác nhận có mặt.",
    "Kiểm tra thông tin bên dưới trước khi xác nhận điểm danh.",
    "Hệ thống đã ghi nhận sự có mặt của bạn trong buổi học.",
  ][index];
  document.getElementById("success-note").hidden = index !== 2;
}
function show(text, kind = "") {
  message.textContent = text;
  message.className = kind;
}
async function api(path, body) {
  const response = await fetch(`v1/public/attendance/${path}`, {
    method: body ? "POST" : "GET",
    cache: "no-store",
    headers: body ? { "Content-Type": "application/json" } : {},
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(20000),
  });
  const data = await response.json();
  if (!response.ok || !data.success)
    throw new Error(data.message || "Yêu cầu thất bại.");
  return data.data;
}
identity.onsubmit = async (event) => {
  event.preventDefault();
  if (!credential || confirmButton.disabled) return;
  confirmButton.disabled = true;
  switchButton.disabled = true;
  identity.setAttribute("aria-busy", "true");
  show("Đang ghi nhận điểm danh…");
  try {
    const attendance = await api("check-in", {
      idToken: credential,
      qrToken: token,
    });
    show(
      `Điểm danh thành công! ${attendance.studentName || ""} (${attendance.email}) — Buổi #${attendance.sessionId}.`,
      "success",
    );
    credential = null;
    confirmButton.hidden = switchButton.hidden = true;
    setStep(2);
    history.replaceState(null, "", location.pathname);
  } catch (error) {
    show(
      error.message || "Không kết nối được máy chủ. Vui lòng thử lại.",
      "error",
    );
    confirmButton.disabled = false;
  } finally {
    switchButton.disabled = false;
    identity.removeAttribute("aria-busy");
  }
};
switchButton.onclick = () => {
  credential = null;
  google.accounts.id.disableAutoSelect();
  googleButton.hidden = false;
  confirmButton.hidden = switchButton.hidden = identity.hidden = true;
  identity.reset();
  setStep(0);
  show("Chọn lại tài khoản Google trong danh sách lớp.");
};
async function init() {
  if (!token || !/^[a-f0-9]{32}$/.test(token)) {
    show(
      "Đường dẫn QR không hợp lệ. Hãy quét mã đang hiển thị của giảng viên.",
      "error",
    );
    return;
  }
  try {
    const config = await api("config");
    if (!config.clientId)
      throw new Error(
        "Trang điểm danh chưa được cấu hình Google Web. Vui lòng báo giảng viên.",
      );
    await new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = "https://accounts.google.com/gsi/client";
      script.onload = resolve;
      script.onerror = () =>
        reject(
          new Error(
            "Không tải được Google. Kiểm tra kết nối và tải lại trang.",
          ),
        );
      document.head.appendChild(script);
    });
    google.accounts.id.initialize({
      client_id: config.clientId,
      auto_select: false,
      callback: async (response) => {
        credential = response.credential;
        if (!credential) return;
        show("Đang lấy thông tin sinh viên…");
        try {
          const profile = await api("identity", { idToken: credential });
          document.getElementById("full-name").value = profile.fullName;
          document.getElementById("student-code").value = profile.studentCode;
          document.getElementById("email").value = profile.email;
          googleButton.hidden = true;
          identity.hidden = confirmButton.hidden = switchButton.hidden = false;
          confirmButton.disabled = false;
          setStep(1);
          show("Kiểm tra thông tin bên dưới rồi xác nhận điểm danh.");
        } catch (error) {
          credential = null;
          show(error.message || "Không lấy được thông tin sinh viên.", "error");
        }
      },
    });
    // The official Google iframe must fit inside the card on small phones.
    const buttonWidth = Math.max(
      200,
      Math.min(
        320,
        document.querySelector(".check-in-card").clientWidth -
          parseFloat(
            getComputedStyle(document.querySelector(".check-in-card"))
              .paddingLeft,
          ) *
            2,
      ),
    );
    google.accounts.id.renderButton(googleButton, {
      theme: "outline",
      size: "large",
      text: "signin_with",
      width: buttonWidth,
    });
    show("Đăng nhập Google để tiếp tục.");
  } catch (error) {
    show(error.message || "Không kết nối được máy chủ.", "error");
  }
}
init();
