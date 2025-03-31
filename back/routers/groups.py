# routers/groups_router.py
from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
import jwt

from db.database import SessionLocal
from db import models
from services.vk_data import get_group_info
from typing import List

router = APIRouter(prefix="/groups", tags=["groups"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

SECRET_KEY = "SUPER_SECRET_KEY_CHANGE_ME"
ALGORITHM = "HS256"


def get_db():
    """Возвращает сессию БД."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Валидируем JWT-токен.
    Возвращаем {username, role}, иначе 401.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Невалидный токен"
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        role: str = payload.get("role")
        if not username:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception

    return {"username": username, "role": role}


def serialize_db_group(group: models.Group) -> dict:
    """
    Возвращаем только то, что реально храним в БД.
    """
    return {
        "id": group.id,
        "vk_group_id": group.vk_group_id,
        "name": group.name,
        "screen_name": group.screen_name,
    }


@router.post("/")
def create_group(
    group_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Добавляем или привязываем паблик по screen_name.
    """
    screen_name = group_data.get("screen_name")
    if not screen_name:
        raise HTTPException(status_code=400, detail="Необходимо передать screen_name")

    # Находим пользователя в БД
    user = db.query(models.User).filter_by(username=current_user["username"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    # Запрашиваем данные из VK
    try:
        vk_info = get_group_info(screen_name)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Проверяем, есть ли группа в БД (по vk_group_id)
    existing_group = db.query(models.Group).filter_by(vk_group_id=vk_info["id"]).first()

    if existing_group:
        # Проверяем, нет ли уже привязки к пользователю
        link_exists = db.query(models.UserGroup).filter_by(
            user_id=user.id,
            group_id=existing_group.id
        ).first()
        if link_exists:
            raise HTTPException(status_code=400, detail="Эта группа уже есть в вашем списке")

        # Создаём связь
        new_link = models.UserGroup(user_id=user.id, group_id=existing_group.id)
        db.add(new_link)
        db.commit()
        db.refresh(existing_group)

        # Возвращаем данные из БД и VK
        return {
            "db_data": serialize_db_group(existing_group),
            "vk_data": vk_info
        }
    else:
        # Создаём новую запись
        new_group = models.Group(
            vk_group_id=vk_info["id"],
            name=vk_info.get("name"),
            screen_name=vk_info.get("screen_name")
        )
        db.add(new_group)
        db.commit()
        db.refresh(new_group)

        # Связываем с пользователем
        new_link = models.UserGroup(user_id=user.id, group_id=new_group.id)
        db.add(new_link)
        db.commit()

        return {
            "db_data": serialize_db_group(new_group),
            "vk_data": vk_info
        }


@router.get("/")
def list_groups(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Возвращаем список групп, привязанных к пользователю,
    и для каждой делаем запрос к VK, чтобы получить актуальные данные.
    """
    user = db.query(models.User).filter_by(username=current_user["username"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    # Ищем все связи user-group
    user_group_links = db.query(models.UserGroup).filter_by(user_id=user.id).all()
    group_ids = [link.group_id for link in user_group_links]

    groups = db.query(models.Group).filter(models.Group.id.in_(group_ids)).all()

    result = []
    for grp in groups:
        # Запрашиваем из VK по screen_name
        try:
            vk_info = get_group_info(grp.screen_name)
        except ValueError:
            # Если по каким-то причинам не нашли группу в ВК
            vk_info = {}

        result.append({
            "db_data": serialize_db_group(grp),
            "vk_data": vk_info
        })

    return result


@router.delete("/unlink/{group_id}")
def unlink_group_from_user(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Удаляем связь пользователя с группой (не трогаем саму запись о группе).
    """
    user = db.query(models.User).filter_by(username=current_user["username"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    link = db.query(models.UserGroup).filter_by(user_id=user.id, group_id=group_id).first()
    if not link:
        raise HTTPException(status_code=404, detail="У пользователя нет такой привязки")

    db.delete(link)
    db.commit()

    return {"detail": f"Группа id={group_id} отвязана от пользователя {user.username}"}


@router.delete("/{group_id}")
def delete_group(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Удаление самой записи из groups (только для admin).
    """
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Требуется роль admin")

    grp = db.query(models.Group).filter_by(id=group_id).first()
    if not grp:
        raise HTTPException(status_code=404, detail="Группа не найдена")

    db.delete(grp)
    db.commit()
    return {"detail": f"Группа id={group_id} удалена"}
