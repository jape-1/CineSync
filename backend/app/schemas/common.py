"""Bases y respuestas genéricas compartidas por los schemas."""

from pydantic import BaseModel, ConfigDict


class ORMModel(BaseModel):
    """Base para schemas de lectura que se construyen desde modelos ORM."""

    model_config = ConfigDict(from_attributes=True)


class MessageResponse(BaseModel):
    detail: str
