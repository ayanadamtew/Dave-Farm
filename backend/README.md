# Dave Farm Backend 🐍

This is the FastAPI-based backend for the Dave Farm poultry management system.

## 🚀 Quick Start

### 1. Environment Setup
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\\Scripts\\activate
pip install -r requirements.txt
```

### 2. Configuration
Create a `.env` file in this directory:
```env
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/davefarm
SECRET_KEY=your_secret_key
```

### 3. Run with Docker (Recommended)
```bash
docker-compose up -d
```

### 4. Direct Manual Run
```bash
uvicorn app.main:app --reload
```

## 🛠 API Documentation
Once the server is running, you can access the interactive docs at:
- **Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

## 🗄 Database Migrations
Migrations are handled by **Alembic**.
- Generate migration: `alembic revision --autogenerate -m "description"`
- Apply migration: `alembic upgrade head`
