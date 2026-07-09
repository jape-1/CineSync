"""Rutas de productos de dulcería (listado público, gestión admin)."""

from fastapi import APIRouter, Depends, status

from app.core.security import require_admin
from app.deps import DbDep
from app.schemas.dulceria import ProductoCreate, ProductoRead, ProductoUpdate
from app.services import dulceria as dulceria_service

router = APIRouter(prefix="/productos", tags=["productos"])


@router.get("", response_model=list[ProductoRead])
async def listar(db: DbDep) -> list[ProductoRead]:
    productos = await dulceria_service.listar_productos(db)
    return [ProductoRead.model_validate(p) for p in productos]


@router.post(
    "",
    response_model=ProductoRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_admin)],
)
async def crear(data: ProductoCreate, db: DbDep) -> ProductoRead:
    producto = await dulceria_service.crear_producto(db, data)
    return ProductoRead.model_validate(producto)


@router.patch(
    "/{producto_id}", response_model=ProductoRead, dependencies=[Depends(require_admin)]
)
async def actualizar(
    producto_id: int, data: ProductoUpdate, db: DbDep
) -> ProductoRead:
    producto = await dulceria_service.actualizar_producto(db, producto_id, data)
    return ProductoRead.model_validate(producto)
