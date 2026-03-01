import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from ..core.database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    farm_name = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    flocks = relationship("Flock", back_populates="owner")
    daily_logs = relationship("DailyLog", back_populates="owner")
    egg_sales = relationship("EggSale", back_populates="owner")
    expenses = relationship("Expense", back_populates="owner")

class Flock(Base):
    __tablename__ = "flocks"
    id = Column(String, primary_key=True) # UUID string from mobile
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    start_date = Column(DateTime, nullable=False)
    initial_bird_count = Column(Integer, nullable=False)
    current_bird_count = Column(Integer, nullable=False)
    breed = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    owner = relationship("User", back_populates="flocks")
    daily_logs = relationship("DailyLog", back_populates="flock")

class DailyLog(Base):
    __tablename__ = "daily_logs"
    id = Column(String, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    flock_id = Column(String, ForeignKey("flocks.id"), nullable=False)
    date = Column(DateTime, nullable=False)
    good_eggs = Column(Integer, default=0)
    broken_eggs = Column(Integer, default=0)
    dead_birds = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="daily_logs")
    flock = relationship("Flock", back_populates="daily_logs")

class EggSale(Base):
    __tablename__ = "egg_sales"
    id = Column(String, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    customer_name = Column(String, nullable=True)
    date = Column(DateTime, nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Float, nullable=False)
    total_price = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="egg_sales")

class Expense(Base):
    __tablename__ = "expenses"
    id = Column(String, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    date = Column(DateTime, nullable=False)
    category = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("User", back_populates="expenses")
