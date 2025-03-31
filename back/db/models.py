# db/models.py
from sqlalchemy import (
    Column, Integer, String, DateTime, ForeignKey, 
    func
)
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), default="user")

    # Новые поля
    name = Column(String(100), nullable=True)
    telegram = Column(String(100), nullable=True)
    date_of_registration = Column(DateTime, default=func.now())
    unique_code = Column(String(50), unique=True, nullable=True)

    user_groups = relationship("UserGroup", back_populates="user")

    # Если нужно видеть все связи SMM-директора -> аналитики (с позиции директора)
    # И связи СММ-аналитик -> директор (с позиции аналитика), можно прописать 2 relationships,
    # но проще сделать всё через таблицу SmmDirectorAnalyst

class Group(Base):
    __tablename__ = "groups"

    id = Column(Integer, primary_key=True, autoincrement=True)
    vk_group_id = Column(Integer, unique=True, nullable=False)
    name = Column(String(255), nullable=True)
    screen_name = Column(String(255), nullable=True)

    user_groups = relationship("UserGroup", back_populates="group")

class UserGroup(Base):
    __tablename__ = "user_groups"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    group_id = Column(Integer, ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)

    user = relationship("User", back_populates="user_groups")
    group = relationship("Group", back_populates="user_groups")

# Таблица для связи "SMM-директор" -> "SMM-аналитики"
class SmmDirectorAnalyst(Base):
    __tablename__ = "smm_director_analysts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    director_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    analyst_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Связи
    director = relationship("User", foreign_keys=[director_id])
    analyst = relationship("User", foreign_keys=[analyst_id])
