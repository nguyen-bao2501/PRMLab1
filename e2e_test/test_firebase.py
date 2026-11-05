import os

import pytest


@pytest.mark.asyncio
async def test_tc13_attendance_report_filter(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app signed in. Open the test Attendance Report, "
        "read the total and attended counts, select the 'Có mặt' filter, and "
        "report whether matching rows are visible. Do not report student names, "
        "IDs, or emails. Return JSON with observed fields: screen, total_count "
        "(integer), attended_count (integer), present_filter_selected (boolean), "
        "matching_rows_visible (boolean)."
    )
    assert observed.get("screen") == "Báo cáo điểm danh", observed
    assert isinstance(observed.get("total_count"), int), observed
    assert isinstance(observed.get("attended_count"), int), observed
    assert observed["total_count"] >= observed["attended_count"] >= 0, observed
    assert observed.get("present_filter_selected") is True, observed


@pytest.mark.asyncio
async def test_tc14_export_pdf_to_cloud_storage(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app signed in. Open the test Attendance Report "
        "and export its PDF to Firebase Cloud Storage. Wait until the upload "
        "finishes. Report screen, upload_succeeded (boolean), storage_path, and "
        "pdf_bytes as an integer. Never return the download URL or student "
        "information. Return exactly one JSON object with these fields inside "
        "observed."
    )
    assert observed.get("upload_succeeded") is True, observed
    assert str(observed.get("storage_path", "")).startswith("reports/"), observed
    assert isinstance(observed.get("pdf_bytes"), int), observed
    assert observed["pdf_bytes"] > 0, observed


@pytest.mark.asyncio
async def test_tc15_remote_config_values_visible(artemis_task, required_env):
    expected_ocr = required_env("ARTEMIS_EXPECTED_OCR_ENABLED").lower()
    expected_interval = int(required_env("ARTEMIS_EXPECTED_SYNC_INTERVAL"))
    if expected_ocr not in {"true", "false"}:
        pytest.fail("ARTEMIS_EXPECTED_OCR_ENABLED must be 'true' or 'false'.")

    observed = await artemis_task(
        "Open the FPT attendance app signed in. Open Firebase Demo Area, tap "
        "'Fetch & Activate từ Console', wait for completion, and report the "
        "visible Remote Config values: ocr_enabled (boolean) and "
        "sync_interval_seconds (integer). Return exactly one JSON object with "
        "these fields inside observed."
    )
    assert observed.get("ocr_enabled") is (expected_ocr == "true"), observed
    assert observed.get("sync_interval_seconds") == expected_interval, observed


@pytest.mark.asyncio
async def test_tc16_receive_and_open_native_push(artemis_task, required_env):
    expected_title = required_env("ARTEMIS_TEST_PUSH_TITLE")
    observed = await artemis_task(
        "Open the FPT attendance app signed in. Handle the Android notification "
        "permission dialog if it appears. A Firebase Console test push has been "
        f"sent with title '{expected_title}'. Receive it, open it from the "
        "Android notification shade, and report notification_title, "
        "destination_screen, and whether the notification opened the app. "
        "Return one JSON object with these fields inside observed."
    )
    assert observed.get("notification_title") == expected_title, observed
    assert observed.get("notification_opened_app") is True, observed
    assert observed.get("destination_screen"), observed


@pytest.mark.asyncio
async def test_tc18_search_event_is_in_firebase_analytics_logcat(
    artemis_task,
    analytics_logcat,
):
    code = os.getenv("ARTEMIS_TEST_CLASS_CODE", "PRM393")
    analytics_logcat.begin_capture()
    observed = await artemis_task(
        "Open the FPT attendance app signed in, open 'Lớp học của tôi', and "
        f"search for '{code}'. Report the exact search term and visible result "
        "count as an integer. Return JSON with observed fields: search_term, "
        "result_count."
    )
    assert observed.get("search_term") == code, observed
    assert isinstance(observed.get("result_count"), int), observed
    assert observed["result_count"] > 0, observed

    event_logs = analytics_logcat.wait_for_event("search")
    assert event_logs, (
        "Firebase Analytics 'search' event was not found in FA/FA-SVC Logcat. "
        "Confirm Firebase is initialized and Analytics debug mode is enabled."
    )
