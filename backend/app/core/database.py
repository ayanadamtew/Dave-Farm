from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from urllib.parse import urlparse, urlunparse
from app.core.config import settings

# Robustly handle Render/Neon connection strings
db_url = settings.DATABASE_URL
connect_args = {}

if "sslmode=require" in db_url or "ssl=true" in db_url.lower():
    # Force SSL for asyncpg
    connect_args["ssl"] = True
    # Strip ALL query parameters to prevent "database does not exist" errors
    # caused by leftover '&' characters after manual string replacement.
    parsed = urlparse(db_url)
    db_url = urlunparse(parsed._replace(query=""))

engine = create_async_engine(db_url, echo=False, connect_args=connect_args)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
