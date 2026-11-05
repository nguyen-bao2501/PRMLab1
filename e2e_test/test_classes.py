import os

import pytest


def _class_code() -> str:
    return os.getenv("ARTEMIS_TEST_CLASS_CODE", "PRM393")


@pytest.mark.asyncio
async def test_tc03_open_class_list_from_navigation(artemis_task):
    observed = await artemis_task(
        "Open the FPT attendance app. Make sure a dedicated test account is "
        "signed in, returning to the login screen and signing in if needed. "
        "Open the navigation drawer, choose 'Lớp học của tôi', and report the "
        "visible screen title. Return JSON with observed fields: screen."
    )
    assert observed.get("screen") == "Lớp học của tôi", observed


@pytest.mark.asyncio
async def test_tc04_search_for_test_class(artemis_task):
    code = _class_code()
    observed = await artemis_task(
        f"Open the FPT attendance app with the test account signed in. Open "
        f"'Lớp học của tôi' and search for the exact class code '{code}'. "
        "Report the exact search_term, visible result_count as an integer, and "
        "one matching subject_code. Return exactly one JSON object with those "
        "fields inside observed."
    )
    assert observed.get("search_term") == code, observed
    assert isinstance(observed.get("result_count"), int), observed
    assert observed["result_count"] > 0, observed
    assert code.lower() in str(observed.get("subject_code", "")).lower(), observed


@pytest.mark.asyncio
async def test_tc05_search_empty_state(artemis_task):
    query = "ARTEMIS_NO_SUCH_CLASS_938274"
    observed = await artemis_task(
        "Open the FPT attendance app with the test account signed in. Open "
        f"'Lớp học của tôi' and search for the exact nonexistent code '{query}'. "
        "Report whether the empty state is visible and the visible result count. "
        "Return JSON with observed fields: empty_state_visible (boolean), "
        "result_count (integer), screen."
    )
    assert observed.get("screen") == "Lớp học của tôi", observed
    assert observed.get("empty_state_visible") is True, observed
    assert observed.get("result_count") == 0, observed


@pytest.mark.asyncio
async def test_tc06_open_class_detail(artemis_task):
    code = _class_code()
    observed = await artemis_task(
        f"Open the FPT attendance app signed in. Open 'Lớp học của tôi', search "
        f"for '{code}', and open the matching class. Report the screen, "
        "subject_code, and class_name shown. Return one JSON object with those "
        "fields inside observed."
    )
    assert observed.get("screen") == "Chi tiết lớp", observed
    assert code.lower() in str(observed.get("subject_code", "")).lower(), observed
    assert observed.get("class_name"), observed


@pytest.mark.asyncio
async def test_tc07_import_test_sheet(artemis_task, required_env):
    tab = required_env("ARTEMIS_TEST_SHEET_TAB")
    code = _class_code()
    observed = await artemis_task(
        f"Open the FPT attendance app signed in. Open 'Lớp học của tôi', choose "
        f"the class '{code}', then open its Import Sheet flow. Use only the "
        "already configured isolated test Sheet; do not display or report its "
        f"URL. Choose the tab '{tab}'. If the exact synthetic rows are already "
        "present in this test class, verify them without importing duplicates; "
        "otherwise complete the import. Report the selected tab, whether the "
        "result step is visible, and imported_count as an integer. Do not return "
        "student names, IDs, or emails. Return exactly one JSON object with "
        "those fields inside observed."
    )
    assert observed.get("result_visible") is True, observed
    assert observed.get("selected_tab") == tab, observed
    assert isinstance(observed.get("imported_count"), int), observed
    assert observed["imported_count"] > 0, observed


@pytest.mark.asyncio
async def test_tc08_invalid_sheet_shows_recovery_path(artemis_task):
    code = _class_code()
    observed = await artemis_task(
        f"Open the FPT attendance app signed in. Open 'Lớp học của tôi', choose "
        f"'{code}', then open Import Sheet. Replace the Sheet URL with the "
        "invalid text 'not-a-google-sheet-url' and attempt to load its tabs. "
        "Report whether a visible error or retry path appears and whether the "
        "app remains open. Return JSON with observed fields: error_visible "
        "(boolean), retry_available (boolean), app_open (boolean), import_succeeded "
        "(boolean)."
    )
    assert observed.get("error_visible") is True, observed
    assert observed.get("retry_available") is True, observed
    assert observed.get("app_open") is True, observed
    assert observed.get("import_succeeded") is False, observed
