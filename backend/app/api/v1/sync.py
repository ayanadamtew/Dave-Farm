from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.dialects.postgresql import insert
from typing import List
import jwt

from app.core.database import get_db
from app.core.config import settings
from app.models.domain import User, Flock, DailyLog, EggSale, Expense
from app.schemas.dto import FlockDto, DailyLogDto, EggSaleDto, ExpenseDto, RestoreResponse

router = APIRouter()
security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    try:
        payload = jwt.decode(credentials.credentials, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid auth credentials")
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid auth credentials")
        
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user


@router.post("/flocks", status_code=status.HTTP_200_OK)
async def sync_flocks(items: List[FlockDto], current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    if not items: return {"status": "ok"}
    
    values = []
    for item in items:
        val = item.model_dump()
        val["user_id"] = current_user.id
        values.append(val)
        
    stmt = insert(Flock).values(values)
    stmt = stmt.on_conflict_do_update(
        index_elements=['id'],
        set_={k: stmt.excluded[k] for k in ['name', 'start_date', 'initial_bird_count', 'current_bird_count', 'breed', 'updated_at']}
    )
    await db.execute(stmt)
    await db.commit()
    return {"status": "ok", "count": len(items)}


@router.post("/daily_logs", status_code=status.HTTP_200_OK)
async def sync_daily_logs(items: List[DailyLogDto], current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    if not items: return {"status": "ok"}
    
    values = [{"user_id": current_user.id, **item.model_dump()} for item in items]
    stmt = insert(DailyLog).values(values)
    stmt = stmt.on_conflict_do_update(
        index_elements=['id'],
        set_={k: stmt.excluded[k] for k in ['good_eggs', 'broken_eggs', 'dead_birds']}
    )
    await db.execute(stmt)
    await db.commit()
    return {"status": "ok", "count": len(items)}


@router.post("/egg_sales", status_code=status.HTTP_200_OK)
async def sync_egg_sales(items: List[EggSaleDto], current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    if not items: return {"status": "ok"}
    
    values = [{"user_id": current_user.id, **item.model_dump()} for item in items]
    stmt = insert(EggSale).values(values)
    stmt = stmt.on_conflict_do_update(
        index_elements=['id'],
        set_={k: stmt.excluded[k] for k in ['customer_name', 'quantity', 'unit_price', 'total_price']}
    )
    await db.execute(stmt)
    await db.commit()
    return {"status": "ok", "count": len(items)}


@router.post("/expenses", status_code=status.HTTP_200_OK)
async def sync_expenses(items: List[ExpenseDto], current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    if not items: return {"status": "ok"}
    
    values = [{"user_id": current_user.id, **item.model_dump()} for item in items]
    stmt = insert(Expense).values(values)
    stmt = stmt.on_conflict_do_update(
        index_elements=['id'],
        set_={k: stmt.excluded[k] for k in ['category', 'amount', 'notes']}
    )
    await db.execute(stmt)
    await db.commit()
    return {"status": "ok", "count": len(items)}


@router.get("/restore", response_model=RestoreResponse)
async def restore_data(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Flocks
    flocks_res = await db.execute(select(Flock).where(Flock.user_id == current_user.id))
    flocks = flocks_res.scalars().all()
    
    # Logs
    logs_res = await db.execute(select(DailyLog).where(DailyLog.user_id == current_user.id))
    logs = logs_res.scalars().all()
    
    # Sales
    sales_res = await db.execute(select(EggSale).where(EggSale.user_id == current_user.id))
    sales = sales_res.scalars().all()
    
    # Expenses
    expenses_res = await db.execute(select(Expense).where(Expense.user_id == current_user.id))
    expenses = expenses_res.scalars().all()

    return RestoreResponse(
        flocks=[FlockDto.model_validate(f, from_attributes=True) for f in flocks],
        daily_logs=[DailyLogDto.model_validate(l, from_attributes=True) for l in logs],
        egg_sales=[EggSaleDto.model_validate(s, from_attributes=True) for s in sales],
        expenses=[ExpenseDto.model_validate(e, from_attributes=True) for e in expenses],
    )
