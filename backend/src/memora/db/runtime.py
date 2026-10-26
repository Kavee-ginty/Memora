from functools import lru_cache

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine, make_url


@lru_cache(maxsize=4)
def database_engine(database_url: str) -> Engine:
    connect_args = (
        {"connect_timeout": 10} if make_url(database_url).drivername == "postgresql+psycopg" else {}
    )
    return create_engine(database_url, pool_pre_ping=True, connect_args=connect_args)
