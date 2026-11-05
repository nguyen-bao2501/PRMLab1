from __future__ import annotations

import json
import os
import re
import subprocess
import time
from collections.abc import Awaitable, Callable, Iterator, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pytest
from artemis_client import ArtemisClient, TaskResult

ARTEMIS_PACKAGE = os.getenv("ARTEMIS_APP_PACKAGE", "com.example.prm")
ARTIFACTS_DIR = Path(__file__).parent / "artifacts"


def _structured_output(result: TaskResult) -> Mapping[str, Any]:
    output = result.output
    if isinstance(output, Mapping):
        parsed: Any = output
    elif isinstance(output, str):
        try:
            parsed = json.loads(output)
        except json.JSONDecodeError:
            match = re.search(r"\{[\s\S]*\}", output)
            if match is None:
                pytest.fail(
                    "ARTEMIS output did not contain the requested JSON object: "
                    f"{output!r}"
                )
            try:
                parsed = json.loads(match.group(0))
            except json.JSONDecodeError as error:
                pytest.fail(f"ARTEMIS returned invalid JSON: {error}: {output!r}")
    else:
        pytest.fail(f"ARTEMIS returned no structured output: {output!r}")

    if not isinstance(parsed, Mapping):
        pytest.fail(f"ARTEMIS JSON output must be an object, got {type(parsed).__name__}")

    observed = parsed.get("observed", parsed)
    if not isinstance(observed, Mapping):
        pytest.fail("ARTEMIS output must contain an 'observed' JSON object")
    return observed


def _record_result(
    *,
    test_name: str,
    result: TaskResult,
    duration_seconds: float,
) -> None:
    ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
    record = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "test": test_name,
        "trace_id": result.trace_id,
        "status": result.status,
        "duration_seconds": round(duration_seconds, 3),
        "profile": result.profile or "flash",
    }
    with (ARTIFACTS_DIR / "task-results.jsonl").open("a", encoding="utf-8") as file:
        file.write(json.dumps(record, ensure_ascii=True) + "\n")


@pytest.fixture(scope="session")
def artemis_client() -> ArtemisClient:
    base_url = os.getenv("ARTEMIS_BASE_URL")
    if not base_url:
        pytest.fail("Set ARTEMIS_BASE_URL to the running ARTEMIS daemon URL.")
    device_serial = os.getenv("ARTEMIS_DEVICE_SERIAL")
    if not device_serial:
        pytest.fail("Set ARTEMIS_DEVICE_SERIAL to the Android device serial.")

    return ArtemisClient(
        base_url,
        token=os.getenv("ARTEMIS_TOKEN"),
        device_serial=device_serial,
        default_profile="flash",
        request_timeout=60,
    )


@pytest.fixture
def required_env() -> Callable[[str], str]:
    def get_value(name: str) -> str:
        value = os.getenv(name)
        if not value:
            pytest.skip(f"Set {name} to run this test against the test environment.")
        return value

    return get_value


@pytest.fixture
def artemis_task(
    request: pytest.FixtureRequest,
    artemis_client: ArtemisClient,
) -> Callable[[str], Awaitable[Mapping[str, Any]]]:
    async def run(goal: str) -> Mapping[str, Any]:
        started = time.monotonic()
        result = await artemis_client.run(
            goal,
            profile="flash",
            device_serial=artemis_client.device_serial,
            locked_app_package=ARTEMIS_PACKAGE,
            timeout=900,
        )
        duration = time.monotonic() - started
        _record_result(
            test_name=request.node.name,
            result=result,
            duration_seconds=duration,
        )
        if not result.succeeded:
            pytest.fail(
                f"ARTEMIS task {result.trace_id} ended as {result.status}: "
                f"{result.error or 'no error details'}"
            )
        return _structured_output(result)

    return run


class AndroidAnalyticsLogcat:
    def __init__(self, serial: str, package: str) -> None:
        self.serial = serial
        self.package = package
        self.started_at = 0.0

    def _adb(self, *args: str) -> str:
        completed = subprocess.run(
            ["adb", "-s", self.serial, *args],
            check=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
        return completed.stdout

    def begin_capture(self) -> None:
        self._adb("shell", "setprop", "debug.firebase.analytics.app", self.package)
        self.started_at = time.time()

    def end_capture(self) -> None:
        self._adb("shell", "setprop", "debug.firebase.analytics.app", ".none.")

    def wait_for_event(self, event_name: str, timeout_seconds: int = 30) -> str:
        deadline = time.monotonic() + timeout_seconds
        matching_lines = ""
        while time.monotonic() < deadline:
            logs = self._adb(
                "logcat",
                "-d",
                "-v",
                "epoch",
                "-s",
                "FA:V",
                "FA-SVC:V",
            )
            matching_lines = "\n".join(
                line
                for line in logs.splitlines()
                if event_name.lower() in line.lower()
                and _is_after_capture(line, self.started_at)
            )
            if matching_lines:
                return matching_lines
            time.sleep(2)
        return matching_lines


@pytest.fixture
def analytics_logcat(
    artemis_client: ArtemisClient,
) -> Iterator[AndroidAnalyticsLogcat]:
    serial = artemis_client.device_serial
    if serial is None:
        pytest.fail("ARTEMIS_DEVICE_SERIAL is required for the Analytics Logcat check.")
    logcat = AndroidAnalyticsLogcat(serial, ARTEMIS_PACKAGE)
    yield logcat
    logcat.end_capture()


def _is_after_capture(line: str, started_at: float) -> bool:
    try:
        return float(line.split(maxsplit=1)[0]) >= started_at
    except (ValueError, IndexError):
        return False
