import pytest


@pytest.mark.asyncio
async def test_tc02_dashboard_is_visible(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app. Ensure the dedicated test account is signed "
        "in, returning to the login screen and signing in if needed. Return to "
        "Dashboard and report its visible title and today's session count as an "
        "integer. Return one JSON object with observed fields: screen, "
        "today_session_count."
    )
    assert observed.get("screen") == "Dashboard", observed
    assert isinstance(observed.get("today_session_count"), int), observed
    assert observed["today_session_count"] >= 0, observed


@pytest.mark.asyncio
async def test_tc01_google_sign_in_native_picker(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app. If already signed in, sign out first. "
        "Sign in using the dedicated test Google account from Android's native "
        "account picker. Do not read or report an email address. At the end, "
        "return exactly one JSON object with observed fields: screen, "
        "authenticated (boolean), and native_account_picker_handled (boolean)."
    )
    assert observed.get("screen") == "Dashboard", observed
    assert observed.get("authenticated") is True, observed
    assert observed.get("native_account_picker_handled") is True, observed


@pytest.mark.asyncio
async def test_tc17_sign_out(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app. If signed out, sign in with the dedicated "
        "test Google account. Open the navigation drawer, choose Firebase Demo "
        "Area, sign out, and confirm the dialog. Do not report user information. "
        "At the end, return exactly one JSON object with observed fields: "
        "screen and authenticated (boolean)."
    )
    assert observed.get("screen") == "Login", observed
    assert observed.get("authenticated") is False, observed
