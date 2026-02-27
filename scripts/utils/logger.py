from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional


@dataclass
class Logger:
    """
    Minimal JSON-lines logger.
    Writes to console AND optionally to a log file.
    """
    client_code: str
    run_id: str
    log_file: Optional[Path] = None

    def _now_iso(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    def _emit(self, level: str, message: str, **fields: Any) -> None:
        event: Dict[str, Any] = {
            "ts_utc": self._now_iso(),
            "level": level,
            "client": self.client_code,
            "run_id": self.run_id,
            "message": message,
            **fields,
        }
        line = json.dumps(event, ensure_ascii=False)

        # Console
        print(line)

        # File (JSONL)
        if self.log_file:
            self.log_file.parent.mkdir(parents=True, exist_ok=True)
            with self.log_file.open("a", encoding="utf-8") as f:
                f.write(line + os.linesep)

    def info(self, message: str, **fields: Any) -> None:
        self._emit("INFO", message, **fields)

    def warn(self, message: str, **fields: Any) -> None:
        self._emit("WARN", message, **fields)

    def error(self, message: str, **fields: Any) -> None:
        self._emit("ERROR", message, **fields)


def make_run_id(prefix: str = "run") -> str:
    # Example: run_20260227_031455
    return f"{prefix}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"


def default_log_path(logs_path: str, client_code: str, run_id: str) -> Path:
    # logs/<client>/<run_id>.jsonl
    return Path(logs_path) / client_code / f"{run_id}.jsonl"