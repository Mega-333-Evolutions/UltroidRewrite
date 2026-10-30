# Ultroid - UserBot
# Copyright (C) 2021-2025 TeamUltroid
#
# This file is a part of < https://github.com/TeamUltroid/Ultroid/ >
# Please read the GNU Affero General Public License in
# <https://github.com/TeamUltroid/pyUltroid/blob/main/LICENSE/>.
"""Launch one pyUltroid worker per configured SESSION1..SESSION5.

This is a local replacement for the third-party gist that ``start.sh`` used
to download and execute at runtime. It performs no network access: it only
reads credentials from the process environment and starts child processes.

Each worker receives its credentials through the environment (not argv) so
session strings do not appear in ``ps`` output.
"""

import asyncio
import os
import subprocess
import sys

_CREDENTIALS = ("API_ID", "API_HASH", "SESSION", "REDIS_URI", "REDIS_PASSWORD")
_MAX_WORKERS = 5


def _worker_env(index: int) -> dict[str, str] | None:
    suffix = "" if index == 1 else str(index)
    values = {name: os.environ.get(f"{name}{suffix}") for name in _CREDENTIALS}
    if not all(values.values()):
        return None

    env = os.environ.copy()
    env.update(values)  # type: ignore[arg-type]
    # Each worker owns exactly one session; do not let the primary worker
    # also start SESSION2/SESSION3 and duplicate the other workers.
    env.pop("SESSION2", None)
    env.pop("SESSION3", None)
    return env


async def _wait_forever() -> None:
    await asyncio.Event().wait()


def main() -> None:
    launched = 0
    for index in range(1, _MAX_WORKERS + 1):
        env = _worker_env(index)
        if env is None:
            continue
        subprocess.Popen(
            [sys.executable, "-m", "pyUltroid"],
            env=env,
            stdin=None,
            stdout=None,
            stderr=None,
            cwd=None,
        )
        launched += 1

    if not launched:
        print(
            "multi_session: no complete SESSIONn/API_ID/API_HASH/REDIS_* set found",
            file=sys.stderr,
        )
        return

    print(f"multi_session: launched {launched} worker(s)")
    try:
        asyncio.run(_wait_forever())
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
