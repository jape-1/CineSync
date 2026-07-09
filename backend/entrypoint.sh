#!/usr/bin/env sh
set -e

echo "==> Esperando a la base de datos..."
python -m app.wait_for_db

echo "==> Aplicando migraciones de Alembic..."
alembic upgrade head

echo "==> Seed inicial (administrador)..."
python -m app.seed

echo "==> Iniciando API (uvicorn)..."
# Railway (y otros PaaS) inyectan el puerto en $PORT; en local cae a 8000.
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
