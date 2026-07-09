"""Endpoint de salud — verifica que la app y la BD respondan."""

from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db

router = APIRouter(tags=["health"])

DbDep = Annotated[AsyncSession, Depends(get_db)]


class HealthResponse(BaseModel):
    status: str
    database: str


@router.get("/health")
async def health(db: DbDep) -> HealthResponse:
    try:
        await db.execute(text("SELECT 1"))
        database = "ok"
    except Exception:
        database = "error"
    return HealthResponse(status="ok", database=database)
