"""Cliente async de TMDB (httpx).

Usa el read access token (v4) como Bearer. Devuelve estructuras normalizadas
listas para mapear a la entidad `Pelicula`.
"""

from __future__ import annotations

from datetime import date
from typing import Any

import httpx
from fastapi import HTTPException, status

from app.core.config import settings

_LANG = "es-ES"


def _headers() -> dict[str, str]:
    if not settings.tmdb_read_access_token:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="TMDB no está configurado (falta TMDB_READ_ACCESS_TOKEN)",
        )
    return {
        "Authorization": f"Bearer {settings.tmdb_read_access_token}",
        "accept": "application/json",
    }


async def _get(path: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    url = f"{settings.tmdb_base_url}{path}"
    async with httpx.AsyncClient(timeout=15.0) as client:
        try:
            resp = await client.get(url, headers=_headers(), params=params)
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Error contactando TMDB: {exc}",
            ) from exc
    if resp.status_code == 404:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No encontrado en TMDB")
    if resp.status_code >= 400:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"TMDB respondió {resp.status_code}",
        )
    return resp.json()


def _img(path: str | None, size: str) -> str | None:
    if not path:
        return None
    return f"{settings.tmdb_image_base_url}/{size}{path}"


def _parse_fecha(valor: str | None) -> date | None:
    if not valor:
        return None
    try:
        return date.fromisoformat(valor)
    except ValueError:
        return None


def _certificacion(detalle: dict[str, Any]) -> str | None:
    """Extrae la clasificación (US > PE) del append release_dates, si vino."""
    resultados = (detalle.get("release_dates") or {}).get("results") or []
    por_pais = {r.get("iso_3166_1"): r for r in resultados}
    for pais in ("US", "PE"):
        entradas = (por_pais.get(pais) or {}).get("release_dates") or []
        for e in entradas:
            cert = (e.get("certification") or "").strip()
            if cert:
                return cert
    return None


async def buscar_por_titulo(titulo: str) -> int:
    """Devuelve el tmdb_id del primer resultado de la búsqueda."""
    data = await _get("/search/movie", {"query": titulo, "language": _LANG})
    resultados = data.get("results") or []
    if not resultados:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Sin resultados en TMDB para '{titulo}'",
        )
    return int(resultados[0]["id"])


async def obtener_detalle(tmdb_id: int) -> dict[str, Any]:
    """Detalle normalizado de una película por su id de TMDB."""
    detalle = await _get(
        f"/movie/{tmdb_id}",
        {"language": _LANG, "append_to_response": "release_dates"},
    )
    return {
        "tmdb_id": int(detalle["id"]),
        "titulo": detalle.get("title") or detalle.get("original_title") or "Sin título",
        "sinopsis": detalle.get("overview") or None,
        "poster_url": _img(detalle.get("poster_path"), "w500"),
        "backdrop_url": _img(detalle.get("backdrop_path"), "w1280"),
        "duracion_min": detalle.get("runtime") or None,
        "clasificacion": _certificacion(detalle),
        "fecha_estreno": _parse_fecha(detalle.get("release_date")),
        "calificacion": detalle.get("vote_average") or None,
        "generos": [
            {"tmdb_id": int(g["id"]), "nombre": g["name"]}
            for g in (detalle.get("genres") or [])
        ],
    }
