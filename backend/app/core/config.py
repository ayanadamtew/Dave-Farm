from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Dave Farm"
    DATABASE_URL: str = "postgresql+asyncpg://dave:davepassword@localhost:5432/davefarm"
    SECRET_KEY: str = "your-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30 # 30 days

    class Config:
        env_file = ".env"

settings = Settings()
