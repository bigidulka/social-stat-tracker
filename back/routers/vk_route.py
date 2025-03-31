# routers/groups_router.py
from fastapi import APIRouter, Depends, HTTPException, status, Body, Query
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
import jwt
import time
from typing import Optional, List

from db.database import SessionLocal
from db import models
from services.vk_data import (
    get_group_info,
    get_posts_data,
    get_photos_data,
    get_videos_data
)

router = APIRouter(prefix="/vk_rout", tags=["groups"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

SECRET_KEY = "SUPER_SECRET_KEY_CHANGE_ME"
ALGORITHM = "HS256"


def get_db():
    """
    Возвращает сессию БД.
    """
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


@router.get("/metrics")
def get_group_metrics(
    group_name: str = Query(..., description="Короткое имя или ID группы без «-»"),
    date_from: Optional[int] = Query(None, description="Дата (timestamp) начала периода"),
    date_to: Optional[int] = Query(None, description="Дата (timestamp) конца периода"),
    quick_range: Optional[str] = Query(None, description="Быстрый выбор (week, month, year)"),
    sort_by: Optional[str] = Query("date", description="Сортировка: date|likes|reposts|comments|views"),
    filters: Optional[str] = Query(None, description="Фильтры: text, photo, video (через запятую)"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Маршрут для метрик по группе ВК. 
    """

    # --------------------------------------------------
    # 1. Информация о группе
    # --------------------------------------------------
    try:
        group_data = get_group_info(group_name)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    group_id = group_data["id"]
    owner_id = -abs(group_id)

    # --------------------------------------------------
    # 2. Проверяем quick_range
    # --------------------------------------------------
    now_ts = int(time.time())
    if quick_range == "week":
        date_from = now_ts - 7 * 24 * 3600
        date_to = now_ts
    elif quick_range == "month":
        date_from = now_ts - 30 * 24 * 3600
        date_to = now_ts
    elif quick_range == "year":
        date_from = now_ts - 365 * 24 * 3600
        date_to = now_ts

    # --------------------------------------------------
    # 3. Получаем посты (уже с учётом периода)
    # --------------------------------------------------
    all_posts = get_posts_data(owner_id, date_from, date_to)
    
    # --------------------------------------------------
    # 4. Фильтр по типам контента (text, photo, video)
    # --------------------------------------------------
    if filters:
        chosen_filters = [f.strip().lower() for f in filters.split(",")]
        filtered_posts = []

        for p in all_posts:
            text_ok = ("text" in chosen_filters and p.get("text", "").strip())
            photo_ok = False
            video_ok = False

            atts = p.get("attachments", [])
            for att in atts:
                if att.get("type") == "photo":
                    photo_ok = True
                elif att.get("type") == "video":
                    video_ok = True

            # Условие: достаточно, чтобы совпал хотя бы один
            if text_ok or ("photo" in chosen_filters and photo_ok) or ("video" in chosen_filters and video_ok):
                filtered_posts.append(p)

        all_posts = filtered_posts

    # --------------------------------------------------
    # 5. Сортировка (date|likes|reposts|comments|views)
    # --------------------------------------------------
    def sort_key(post_item):
        sp = post_item.get("stats_post_reach", {})
        if sort_by == "likes":
            return sp.get("reach_subscribers", 0)  # или другой параметр
        elif sort_by == "reposts":
            return sp.get("links", 0)
        elif sort_by == "comments":
            return sp.get("report", 0)
        elif sort_by == "views":
            return sp.get("reach_total", 0)
        else:
            return post_item.get("date", 0)

    all_posts = sorted(all_posts, key=sort_key, reverse=True)

    # --------------------------------------------------
    # 6. Получаем фото и видео (уже с учётом периода)
    # --------------------------------------------------
    all_photos = get_photos_data(owner_id, date_from, date_to)
    all_videos = get_videos_data(owner_id, date_from, date_to)

    return {
        "group_info": group_data,
        "posts": all_posts,
        "photos": all_photos,
        "videos": all_videos
    }
