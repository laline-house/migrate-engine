from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from .env import Env


@dataclass
class DbConfig:
    host: str
    port: int
    name: str
    user: str
    password: str


def db_config_from_env(env: Env) -> Optional[DbConfig]:
    """
    Returns None if DB_* settings aren't present yet (Phase A).
    """
    if not (env.db_host and env.db_port and env.db_name and env.db_user and env.db_password):
        return None

    return DbConfig(
        host=env.db_host,
        port=int(env.db_port),
        name=env.db_name,
        user=env.db_user,
        password=env.db_password,
    )


def pg_conn_str(cfg: DbConfig) -> str:
    # psycopg connection string
    return (
        f"host={cfg.host} port={cfg.port} dbname={cfg.name} "
        f"user={cfg.user} password={cfg.password}"
    )


def connect_psycopg(cfg: DbConfig):
    """
    Lazy import so engine repo doesn't hard-require psycopg until Phase B.
    Usage:
      conn = connect_psycopg(cfg)
    """
    try:
        import psycopg  # type: ignore
    except Exception as e:
        raise RuntimeError(
            "psycopg is not installed. Install it in Phase B (pip install psycopg[binary])."
        ) from e

    return psycopg.connect(pg_conn_str(cfg))