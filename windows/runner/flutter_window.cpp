#include "flutter_window.h"

#include <optional>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <wincred.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter::MethodChannel<flutter::EncodableValue> channel(
      flutter_controller_->engine()->messenger(), "fpt_attendance/desktop",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler([this](const auto& call, auto result) {
    const wchar_t* target = L"FPTAttendance/Session";
    if (call.method_name() == "focus") {
      HWND hwnd = GetHandle();
      ShowWindow(hwnd, IsIconic(hwnd) ? SW_RESTORE : SW_SHOW);
      // Windows may reject activation while another application has focus.
      if (!SetForegroundWindow(hwnd)) {
        FLASHWINFO flash = {sizeof(FLASHWINFO), hwnd, FLASHW_TRAY, 3, 0};
        FlashWindowEx(&flash);
      }
      result->Success();
    } else if (call.method_name() == "readSession") {
      PCREDENTIALW credential = nullptr;
      if (CredReadW(target, CRED_TYPE_GENERIC, 0, &credential)) {
        std::string value(reinterpret_cast<char*>(credential->CredentialBlob),
                          credential->CredentialBlobSize);
        CredFree(credential);
        result->Success(flutter::EncodableValue(value));
      } else if (GetLastError() == ERROR_NOT_FOUND) {
        result->Success();
      } else {
        result->Error("credential_read", "Cannot read Windows credential.");
      }
    } else if (call.method_name() == "writeSession") {
      const auto* value = call.arguments()
          ? std::get_if<std::string>(call.arguments()) : nullptr;
      if (!value || value->size() > CRED_MAX_CREDENTIAL_BLOB_SIZE) {
        result->Error("credential_size", "Invalid session data.");
        return;
      }
      CREDENTIALW credential = {};
      credential.Type = CRED_TYPE_GENERIC;
      credential.TargetName = const_cast<wchar_t*>(target);
      credential.CredentialBlobSize = static_cast<DWORD>(value->size());
      credential.CredentialBlob = reinterpret_cast<LPBYTE>(const_cast<char*>(value->data()));
      credential.Persist = CRED_PERSIST_LOCAL_MACHINE;
      if (CredWriteW(&credential, 0)) {
        result->Success();
      } else {
        result->Error("credential_write", "Cannot save Windows credential.");
      }
    } else if (call.method_name() == "clearSession") {
      if (CredDeleteW(target, CRED_TYPE_GENERIC, 0) || GetLastError() == ERROR_NOT_FOUND) {
        result->Success();
      } else {
        result->Error("credential_delete", "Cannot delete Windows credential.");
      }
    } else {
      result->NotImplemented();
    }
  });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
