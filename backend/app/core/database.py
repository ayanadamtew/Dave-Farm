from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from app.core.config import settings

# Handle Render's ?sslmode=require which asyncpg doesn't like
db_url = settings.DATABASE_URL
connect_args = {}

if "sslmode=require" in db_url:
    db_url = db_url.replace("?sslmode=require", "").replace("&sslmode=require", "")
    connect_args["ssl"] = True

engine = create_async_engine(db_url, echo=False, connect_args=connect_args)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
