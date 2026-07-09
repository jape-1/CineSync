"""Migración inicial — 16 entidades de CineSync + EXCLUDE anti-solapamiento.

Revision ID: 0001
Revises:
Create Date: 2026-07-09

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

from app.models.enums import (
    EstadoAsientoFuncion,
    EstadoQR,
    ResultadoValidacion,
    RolUsuario,
    TipoAsiento,
    TipoDescuento,
    TipoSala,
    TurnoTrabajador,
    pg_enum,
)

# revision identifiers, used by Alembic.
revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Requerida para el EXCLUDE con igualdad de enteros (sala_id) en un índice gist.
    op.execute("CREATE EXTENSION IF NOT EXISTS btree_gist")

    # --- usuarios ---
    op.create_table(
        "usuarios",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("nombre", sa.String(120), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("rol", pg_enum(RolUsuario, 20), nullable=False),
        sa.Column("turno", pg_enum(TurnoTrabajador, 20), nullable=True),
        sa.Column("activo", sa.Boolean(), nullable=False),
        sa.Column("creado_en", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_usuarios_email", "usuarios", ["email"], unique=True)

    # --- generos ---
    op.create_table(
        "generos",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tmdb_id", sa.Integer(), nullable=True),
        sa.Column("nombre", sa.String(80), nullable=False),
        sa.UniqueConstraint("tmdb_id", name="uq_generos_tmdb_id"),
        sa.UniqueConstraint("nombre", name="uq_generos_nombre"),
    )

    # --- peliculas ---
    op.create_table(
        "peliculas",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tmdb_id", sa.Integer(), nullable=True),
        sa.Column("titulo", sa.String(255), nullable=False),
        sa.Column("sinopsis", sa.Text(), nullable=True),
        sa.Column("poster_url", sa.String(500), nullable=True),
        sa.Column("backdrop_url", sa.String(500), nullable=True),
        sa.Column("duracion_min", sa.Integer(), nullable=True),
        sa.Column("clasificacion", sa.String(16), nullable=True),
        sa.Column("fecha_estreno", sa.Date(), nullable=True),
        sa.Column("calificacion", sa.Float(), nullable=True),
        sa.Column("activa", sa.Boolean(), nullable=False),
        sa.Column("creado_en", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.UniqueConstraint("tmdb_id", name="uq_peliculas_tmdb_id"),
    )
    op.create_index("ix_peliculas_titulo", "peliculas", ["titulo"])
    op.create_index("ix_peliculas_activa", "peliculas", ["activa"])

    # --- pelicula_generos (M:N) ---
    op.create_table(
        "pelicula_generos",
        sa.Column("pelicula_id", sa.Integer(), nullable=False),
        sa.Column("genero_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["pelicula_id"], ["peliculas.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["genero_id"], ["generos.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("pelicula_id", "genero_id"),
    )

    # --- salas ---
    op.create_table(
        "salas",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("nombre", sa.String(80), nullable=False),
        sa.Column("tipo", pg_enum(TipoSala, 8), nullable=False),
        sa.Column("filas", sa.Integer(), nullable=False),
        sa.Column("columnas", sa.Integer(), nullable=False),
        sa.Column("activa", sa.Boolean(), nullable=False),
    )

    # --- asientos ---
    op.create_table(
        "asientos",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("sala_id", sa.Integer(), nullable=False),
        sa.Column("fila", sa.String(4), nullable=False),
        sa.Column("numero", sa.Integer(), nullable=False),
        sa.Column("tipo", pg_enum(TipoAsiento, 20), nullable=False),
        sa.ForeignKeyConstraint(["sala_id"], ["salas.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("sala_id", "fila", "numero", name="uq_asiento_sala_fila_numero"),
    )
    op.create_index("ix_asientos_sala_id", "asientos", ["sala_id"])

    # --- funciones ---
    op.create_table(
        "funciones",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("pelicula_id", sa.Integer(), nullable=False),
        sa.Column("sala_id", sa.Integer(), nullable=False),
        sa.Column("inicio", sa.DateTime(timezone=True), nullable=False),
        sa.Column("fin", sa.DateTime(timezone=True), nullable=False),
        sa.Column("precio_base", sa.Numeric(10, 2), nullable=False),
        sa.Column("idioma", sa.String(40), nullable=True),
        sa.Column("formato", sa.String(16), nullable=True),
        sa.ForeignKeyConstraint(["pelicula_id"], ["peliculas.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["sala_id"], ["salas.id"], ondelete="RESTRICT"),
    )
    op.create_index("ix_funciones_pelicula_id", "funciones", ["pelicula_id"])
    op.create_index("ix_funciones_sala_id", "funciones", ["sala_id"])
    # Dos funciones no pueden solaparse en la misma sala.
    op.execute(
        """
        ALTER TABLE funciones
        ADD CONSTRAINT no_solapamiento_sala
        EXCLUDE USING gist (
            sala_id WITH =,
            tstzrange(inicio, fin) WITH &&
        )
        """
    )

    # --- asiento_funciones ---
    op.create_table(
        "asiento_funciones",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("funcion_id", sa.Integer(), nullable=False),
        sa.Column("asiento_id", sa.Integer(), nullable=False),
        sa.Column("estado", pg_enum(EstadoAsientoFuncion, 24), nullable=False),
        sa.Column("reservado_por", sa.Integer(), nullable=True),
        sa.Column("reservado_hasta", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["funcion_id"], ["funciones.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["asiento_id"], ["asientos.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["reservado_por"], ["usuarios.id"], ondelete="SET NULL"),
        sa.UniqueConstraint("funcion_id", "asiento_id", name="uq_asiento_funcion"),
    )
    op.create_index("ix_asiento_funciones_funcion_id", "asiento_funciones", ["funcion_id"])
    op.create_index("ix_asiento_funciones_asiento_id", "asiento_funciones", ["asiento_id"])

    # --- productos ---
    op.create_table(
        "productos",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("nombre", sa.String(120), nullable=False),
        sa.Column("descripcion", sa.Text(), nullable=True),
        sa.Column("precio", sa.Numeric(10, 2), nullable=False),
        sa.Column("imagen_url", sa.String(500), nullable=True),
        sa.Column("categoria", sa.String(60), nullable=True),
        sa.Column("activo", sa.Boolean(), nullable=False),
    )

    # --- combos ---
    op.create_table(
        "combos",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("nombre", sa.String(120), nullable=False),
        sa.Column("descripcion", sa.Text(), nullable=True),
        sa.Column("precio", sa.Numeric(10, 2), nullable=False),
        sa.Column("imagen_url", sa.String(500), nullable=True),
        sa.Column("activo", sa.Boolean(), nullable=False),
    )

    # --- combo_productos (M:N) ---
    op.create_table(
        "combo_productos",
        sa.Column("combo_id", sa.Integer(), nullable=False),
        sa.Column("producto_id", sa.Integer(), nullable=False),
        sa.Column("cantidad", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["combo_id"], ["combos.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["producto_id"], ["productos.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("combo_id", "producto_id"),
    )

    # --- promociones ---
    op.create_table(
        "promociones",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("codigo", sa.String(40), nullable=False),
        sa.Column("descripcion", sa.Text(), nullable=True),
        sa.Column("tipo_descuento", pg_enum(TipoDescuento, 16), nullable=False),
        sa.Column("valor", sa.Numeric(10, 2), nullable=False),
        sa.Column("activo", sa.Boolean(), nullable=False),
        sa.Column("valido_desde", sa.DateTime(timezone=True), nullable=True),
        sa.Column("valido_hasta", sa.DateTime(timezone=True), nullable=True),
        sa.Column("usos_maximos", sa.Integer(), nullable=True),
        sa.Column("usos_actuales", sa.Integer(), nullable=False),
        sa.UniqueConstraint("codigo", name="uq_promociones_codigo"),
    )
    op.create_index("ix_promociones_codigo", "promociones", ["codigo"], unique=True)

    # --- compras ---
    op.create_table(
        "compras",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("usuario_id", sa.Integer(), nullable=False),
        sa.Column("funcion_id", sa.Integer(), nullable=False),
        sa.Column("promocion_id", sa.Integer(), nullable=True),
        sa.Column("subtotal", sa.Numeric(10, 2), nullable=False),
        sa.Column("descuento", sa.Numeric(10, 2), nullable=False),
        sa.Column("total", sa.Numeric(10, 2), nullable=False),
        sa.Column("qr_codigo", sa.String(512), nullable=False),
        sa.Column("qr_estado", pg_enum(EstadoQR, 16), nullable=False),
        sa.Column("usado_en", sa.DateTime(timezone=True), nullable=True),
        sa.Column("creado_en", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["usuario_id"], ["usuarios.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["funcion_id"], ["funciones.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["promocion_id"], ["promociones.id"], ondelete="SET NULL"),
        sa.UniqueConstraint("qr_codigo", name="uq_compras_qr_codigo"),
    )
    op.create_index("ix_compras_usuario_id", "compras", ["usuario_id"])
    op.create_index("ix_compras_funcion_id", "compras", ["funcion_id"])
    op.create_index("ix_compras_qr_codigo", "compras", ["qr_codigo"], unique=True)

    # --- compra_asientos (M:N) ---
    op.create_table(
        "compra_asientos",
        sa.Column("compra_id", sa.Integer(), nullable=False),
        sa.Column("asiento_funcion_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["compra_id"], ["compras.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["asiento_funcion_id"], ["asiento_funciones.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("compra_id", "asiento_funcion_id"),
    )

    # --- compra_productos ---
    op.create_table(
        "compra_productos",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("compra_id", sa.Integer(), nullable=False),
        sa.Column("producto_id", sa.Integer(), nullable=True),
        sa.Column("combo_id", sa.Integer(), nullable=True),
        sa.Column("cantidad", sa.Integer(), nullable=False),
        sa.Column("precio_unitario", sa.Numeric(10, 2), nullable=False),
        sa.ForeignKeyConstraint(["compra_id"], ["compras.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["producto_id"], ["productos.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["combo_id"], ["combos.id"], ondelete="RESTRICT"),
        sa.CheckConstraint(
            "(producto_id IS NOT NULL) <> (combo_id IS NOT NULL)",
            name="ck_compra_producto_uno_u_otro",
        ),
    )
    op.create_index("ix_compra_productos_compra_id", "compra_productos", ["compra_id"])

    # --- validaciones_qr ---
    op.create_table(
        "validaciones_qr",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("compra_id", sa.Integer(), nullable=True),
        sa.Column("trabajador_id", sa.Integer(), nullable=False),
        sa.Column("codigo_escaneado", sa.String(512), nullable=False),
        sa.Column("resultado", pg_enum(ResultadoValidacion, 16), nullable=False),
        sa.Column("escaneado_en", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["compra_id"], ["compras.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["trabajador_id"], ["usuarios.id"], ondelete="RESTRICT"),
    )
    op.create_index("ix_validaciones_qr_compra_id", "validaciones_qr", ["compra_id"])
    op.create_index("ix_validaciones_qr_trabajador_id", "validaciones_qr", ["trabajador_id"])


def downgrade() -> None:
    op.drop_table("validaciones_qr")
    op.drop_table("compra_productos")
    op.drop_table("compra_asientos")
    op.drop_table("compras")
    op.drop_table("promociones")
    op.drop_table("combo_productos")
    op.drop_table("combos")
    op.drop_table("productos")
    op.drop_table("asiento_funciones")
    op.execute("ALTER TABLE funciones DROP CONSTRAINT IF EXISTS no_solapamiento_sala")
    op.drop_table("funciones")
    op.drop_table("asientos")
    op.drop_table("salas")
    op.drop_table("pelicula_generos")
    op.drop_table("peliculas")
    op.drop_table("generos")
    op.drop_table("usuarios")
    op.execute("DROP EXTENSION IF EXISTS btree_gist")
