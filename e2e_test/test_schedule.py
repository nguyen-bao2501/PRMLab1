import pytest


@pytest.mark.asyncio
async def test_tc09_open_week_and_session_detail(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app signed in. Use the navigation drawer to "
        "open 'Lịch dạy tuần'. Select a day that has a test session and open "
        "that session's details. Report screen, subject_code, date, and room "
        "exactly as displayed. Return one JSON object with these fields inside "
        "observed."
    )
    assert observed.get("screen") == "Chi tiết tiết học", observed
    assert observed.get("subject_code"), observed
    assert observed.get("date"), observed
    assert observed.get("room"), observed


@pytest.mark.asyncio
async def test_tc10_create_or_verify_test_schedule(artemis_task, required_env):
    date = required_env("ARTEMIS_TEST_SESSION_DATE")
    room = required_env("ARTEMIS_TEST_SESSION_ROOM")
    observed = await artemis_task(
        "Open the FPT attendance app signed in and open 'Xếp lịch tiết học'. "
        f"Create a session for date '{date}' and room '{room}' using the "
        "configured test class and slot. If a session with exactly these test "
        "values already exists, open and verify it instead of creating a "
        "duplicate. Report screen, session_saved (boolean), date, room, and "
        "slot. Return one JSON object with those fields inside observed."
    )
    assert observed.get("session_saved") is True, observed
    assert observed.get("date") == date, observed
    assert observed.get("room") == room, observed
    assert observed.get("slot"), observed


@pytest.mark.asyncio
async def test_tc11_past_schedule_date_is_rejected(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app signed in and open 'Xếp lịch tiết học'. "
        "Enter a date in the past, submit the form, and inspect the result. "
        "Report whether validation feedback is visible and whether the invalid "
        "session was saved. Return JSON with observed fields: validation_visible "
        "(boolean), session_saved (boolean), error_message_visible (boolean)."
    )
    assert observed.get("validation_visible") is True, observed
    assert observed.get("session_saved") is False, observed
    assert observed.get("error_message_visible") is True, observed


@pytest.mark.asyncio
async def test_tc12_open_live_attendance(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app signed in. Find a currently active test "
        "session in Dashboard or the weekly schedule, open its live attendance "
        "screen, and report the subject_code, whether the QR code is visible, "
        "and total_count as an integer. Do not scan or submit the QR. Return "
        "one JSON object with these fields inside observed."
    )
    assert observed.get("screen") == "Điểm danh", observed
    assert observed.get("qr_visible") is True, observed
    assert isinstance(observed.get("total_count"), int), observed
    assert observed["total_count"] >= 0, observed
