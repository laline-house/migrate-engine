from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional


@dataclass
class Env:
    client_code: str
    workspace_path: str
    extracts_path: str
    logs_path: str
    outputs_path: str

    db_host: Optional[str] = None
    db_port: Optional[str] = None
    db_name: Optional[str] = None
    db_user: Optional[str] = None
    db_password: Optional[str] = None


def load_env_file(env_path: str) -> Dict[str, str]:
    """
    Loads a simple KEY=VALUE .env file (no quoting/expansion).
    Ignores blank lines and # comments.
    """
    p = Path(env_path)
    if not p.exists():
        raise FileNotFoundError(f".env not found: {env_path}")

    data: Dict[str, str] = {}
    for raw_line in p.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        data[k.strip()] = v.strip()
    return data


def env_from_file(env_path: str) -> Env:
    data = load_env_file(env_path)

    def req(key: str) -> str:
        if key not in data or not data[key]:
            raise ValueError(f"Missing required .env key: {key}")
        return data[key]

    return Env(
        client_code=req("CLIENT_CODE"),
        workspace_path=req("WORKSPACE_PATH"),
        extracts_path=req("EXTRACTS_PATH"),
        logs_path=req("LOGS_PATH"),
        outputs_path=req("OUTPUTS_PATH"),
        db_host=data.get("DB_HOST"),
        db_port=data.get("DB_PORT"),
        db_name=data.get("DB_NAME"),
        db_user=data.get("DB_USER"),
        db_password=data.get("DB_PASSWORD"),
    )


def apply_to_process_env(env: Env) -> None:
    """
    Optional helper if you want to standardise env vars for child processes.
    """
    os.environ["CLIENT_CODE"] = env.client_code
    os.environ["WORKSPACE_PATH"] = env.workspace_path
    os.environ["EXTRACTS_PATH"] = env.extracts_path
    os.environ["LOGS_PATH"] = env.logs_path
    os.environ["OUTPUTS_PATH"] = env.outputs_path