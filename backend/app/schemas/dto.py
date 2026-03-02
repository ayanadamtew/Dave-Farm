from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
import uuid

# --- Users ---

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    farm_name: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    farm_name: str
    email: str

class TokenData(BaseModel):
    user_id: Optional[str] = None

# --- Sync Data Models ---
# Same structure as the Dart app

class FlockDto(BaseModel):
    id: str
    name: str
    start_date: datetime
    initial_bird_count: int
    current_bird_count: int
    breed: Optional[str] = None

class DailyLogDto(BaseModel):
    id: str
    flock_id: str
    date: datetime
    good_eggs: int
    broken_eggs: int
    damaged_eggs: int
    dead_birds: int
    total_eggs: int

    class Config:
        from_attributes = True

class EggSaleDto(BaseModel):
    id: str
    customer_name: Optional[str] = None
    date: datetime
    quantity: int
    unit_price: float
    total_price: float

class ExpenseDto(BaseModel):
    id: str
    date: datetime
    category: str
    amount: float
    notes: Optional[str] = None

# --- Restore Structure ---

class RestoreResponse(BaseModel):
    flocks: List[FlockDto]
    daily_logs: List[DailyLogDto]
    egg_sales: List[EggSaleDto]
    expenses: List[ExpenseDto]
