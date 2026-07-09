"""Configuración central de la aplicación.

Lee las variables desde `backend/.env` (o el entorno del contenedor). Nunca se
hardcodean secretos aquí: los valores sensibles llegan por variable de entorno.
"""

from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @field_validator("database_url", mode="after")
    @classmethod
    def _use_asyncpg(cls, v: str) -> str:
        """Normaliza la URL a asyncpg.

        Railway/Heroku entregan `postgres://` o `postgresql://`; SQLAlchemy async
        necesita `postgresql+asyncpg://`. Así se puede pegar la URL de Railway tal
        cual sin reescribirla a mano.
        """
        if v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql+asyncpg://", 1)
        if v.startswith("postgresql://"):
            return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v

    # --- App ---
    app_name: str = "CineSync API"
    api_v1_prefix: str = "/api/v1"
    debug: bool = False

    # --- Base de datos ---
    # Formato async: postgresql+asyncpg://usuario:password@db:5432/cinesync
    database_url: str = "postgresql+asyncpg://cinesync:cinesync@db:5432/cinesync"

    # --- JWT ---
    jwt_secret: str = "dev-insecure-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 14
    reset_token_expire_minutes: int = 30

    # --- Seed inicial de administrador (idempotente, corre en el entrypoint) ---
    seed_admin_email: str = "admin@cinesync.com"
    seed_admin_password: str = "admin123"
    seed_admin_nombre: str = "Administrador"

    # --- TMDB ---
    tmdb_api_key: str = ""
    tmdb_read_access_token: str = ""
    tmdb_base_url: str = "https://api.themoviedb.org/3"
    tmdb_image_base_url: str = "https://image.tmdb.org/t/p"

    # --- Reglas de negocio en tiempo real ---
    seat_lock_ttl_seconds: int = 300  # 5 min de bloqueo temporal de asiento
    seat_lock_sweep_seconds: int = 10  # cada cuánto corre la tarea de expiración

    # --- Compras ---
    # Ventana mínima (horas antes del inicio) para poder cancelar una compra.
    cancel_window_hours: int = 2

    @property
    def sync_database_url(self) -> str:
        """URL síncrona (psycopg) — no usada en runtime, útil para herramientas."""
        return self.database_url.replace("+asyncpg", "")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
