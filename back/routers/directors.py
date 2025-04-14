# directors_routes.py
from fastapi import APIRouter, Depends, HTTPException, status, Body, Path
from sqlalchemy.orm import Session
import jwt

from db.database import SessionLocal
from db import models
from services.vk_data import get_group_info  # та самая функция, что дергает VK API

router = APIRouter(prefix="/directors", tags=["directors"])

SECRET_KEY = "SUPER_SECRET_KEY_CHANGE_ME"
ALGORITHM = "HS256"

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str, db: Session):
    """
    Декодируем токен, ищем пользователя в БД.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        role = payload.get("role")
    except:
        raise HTTPException(status_code=401, detail="Неверный токен")

    user = db.query(models.User).filter_by(username=username).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    return user

def check_director_analyst_link(director: models.User, analyst_id: int, db: Session):
    """
    Проверяем, что user с role=smm_director действительно связан с данным analyst_id
    через таблицу SmmDirectorAnalyst. Если нет — ошибка.
    """
    if director.role != "smm_director":
        raise HTTPException(status_code=403, detail="Требуется роль smm_director")

    link = db.query(models.SmmDirectorAnalyst).filter_by(
        director_id=director.id, analyst_id=analyst_id
    ).first()

    if not link:
        raise HTTPException(
            status_code=403,
            detail="Этот аналитик не связан с вами, доступ запрещён."
        )

    # Возвращаем найденного аналитика
    analyst = db.query(models.User).filter_by(id=analyst_id).first()
    if not analyst:
        raise HTTPException(status_code=404, detail="Аналитик не найден")
    return analyst


def serialize_db_group(group: models.Group) -> dict:
    """Возвращаем только поля, хранимые в БД."""
    return {
        "id": group.id,
        "vk_group_id": group.vk_group_id,
        "name": group.name,
        "screen_name": group.screen_name,
    }


@router.get("/analysts")
def list_analysts_for_director(token: str, db: Session = Depends(get_db)):
    director = get_current_user(token, db)
    if director.role != "smm_director":
        raise HTTPException(status_code=403, detail="У вас нет прав SMM-директора")

    links = db.query(models.SmmDirectorAnalyst).filter_by(director_id=director.id).all()
    result = []
    for link in links:
        analyst_user = link.analyst
        result.append({
            "id": analyst_user.id,
            "username": analyst_user.username,
            "name": analyst_user.name,
            "telegram": analyst_user.telegram,
            "role": analyst_user.role,
            "date_of_registration": analyst_user.date_of_registration,
        })
    return result

@router.post("/link-by-code")
def link_by_code(request_data: dict = Body(...), db: Session = Depends(get_db)):
    token = request_data.get("token")
    code = request_data.get("unique_code")

    if not token or not code:
        raise HTTPException(400, "Не передан token или unique_code")

    analyst = get_current_user(token, db)
    if analyst.role != "smm_analyst":
        raise HTTPException(403, "Только аналитик может привязаться через код")

    director_user = db.query(models.User).filter_by(unique_code=code).first()
    if not director_user:
        raise HTTPException(404, "Директор с таким кодом не найден")
    if director_user.role != "smm_director":
        raise HTTPException(400, "Пользователь с таким кодом не является директором")

    link_exists = db.query(models.SmmDirectorAnalyst).filter_by(
        director_id=director_user.id,
        analyst_id=analyst.id
    ).first()
    if link_exists:
        raise HTTPException(400, "Уже привязан")

    new_link = models.SmmDirectorAnalyst(
        director_id=director_user.id,
        analyst_id=analyst.id
    )
    db.add(new_link)
    db.commit()

    return {"detail": f"Аналитик {analyst.username} привязан к директору {director_user.username}"}

@router.delete("/unlink-analyst/{analyst_id}")
def unlink_analyst(token: str, analyst_id: int, db: Session = Depends(get_db)):
    director = get_current_user(token, db)
    if director.role != "smm_director":
        raise HTTPException(status_code=403, detail="Требуется роль smm_director")

    link = db.query(models.SmmDirectorAnalyst).filter_by(
        director_id=director.id,
        analyst_id=analyst_id
    ).first()
    if not link:
        raise HTTPException(status_code=404, detail="Привязка не найдена")

    db.delete(link)
    db.commit()
    return {"detail": f"Аналитик id={analyst_id} отвязан от директора {director.username}"}

# Новые маршруты, чтобы аналитик мог увидеть/отвязать директора
@router.get("/my-director")
def get_analyst_director(token: str, db: Session = Depends(get_db)):
    analyst = get_current_user(token, db)
    if analyst.role != "smm_analyst":
        raise HTTPException(403, "У вас нет прав SMM-аналитика")

    link = db.query(models.SmmDirectorAnalyst).filter_by(analyst_id=analyst.id).first()
    if not link:
        raise HTTPException(404, "У вас нет SMM-директора")

    director = link.director
    return {
        "id": director.id,
        "username": director.username,
        "name": director.name,
        "telegram": director.telegram,
        "role": director.role,
        "date_of_registration": director.date_of_registration
    }

@router.delete("/unlink-my-director")
def unlink_my_director(token: str, db: Session = Depends(get_db)):
    analyst = get_current_user(token, db)
    if analyst.role != "smm_analyst":
        raise HTTPException(403, "У вас нет прав SMM-аналитика")

    link = db.query(models.SmmDirectorAnalyst).filter_by(analyst_id=analyst.id).first()
    if not link:
        raise HTTPException(status_code=404, detail="Привязка не найдена")

    db.delete(link)
    db.commit()
    return {"detail": f"Вы отвязаны от директора {link.director.username}"}

@router.get("/{analyst_id}/groups")
def list_groups_for_analyst(
    token: str,
    analyst_id: int,
    db: Session = Depends(get_db),
):
    """
    GET /directors/{analyst_id}/groups?token=...
    Возвращаем паблики, привязанные к аналитику 'analyst_id', если
    текущий директор реально связан с этим аналитиком.
    """
    director = get_current_user(token, db)
    analyst = check_director_analyst_link(director, analyst_id, db)

    # Ищем привязки user->group для analyst
    user_group_links = db.query(models.UserGroup).filter_by(user_id=analyst.id).all()
    group_ids = [link.group_id for link in user_group_links]

    groups = db.query(models.Group).filter(models.Group.id.in_(group_ids)).all()

    result = []
    for grp in groups:
        # Как и в groups_router, запрашиваем данные из VK
        try:
            vk_info = get_group_info(grp.screen_name)
        except ValueError:
            vk_info = {}
        result.append({
            "db_data": serialize_db_group(grp),
            "vk_data": vk_info
        })

    return result


@router.post("/{analyst_id}/groups", status_code=201)
def add_group_to_analyst(
    token: str,
    analyst_id: int,
    group_data: dict = Body(...),
    db: Session = Depends(get_db),
):
    """
    POST /directors/{analyst_id}/groups?token=...
    Тело: {"screen_name": "<screen_name>"}
    Привязываем паблик к аналитику (аналогично create_group, 
    но user_id = <analyst.id>, а не директор)
    """
    director = get_current_user(token, db)
    analyst = check_director_analyst_link(director, analyst_id, db)

    screen_name = group_data.get("screen_name")
    if not screen_name:
        raise HTTPException(400, detail="Не передан screen_name")

    # Запрашиваем данные из ВК
    try:
        vk_info = get_group_info(screen_name)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Проверяем, есть ли уже такой group в БД
    existing_group = db.query(models.Group).filter_by(vk_group_id=vk_info["id"]).first()
    if existing_group:
        # Проверяем, нет ли уже привязки аналитика к этой группе
        link_exists = db.query(models.UserGroup).filter_by(
            user_id=analyst.id, group_id=existing_group.id
        ).first()
        if link_exists:
            raise HTTPException(400, detail="У аналитика уже есть этот паблик")

        # Создаем связь
        new_link = models.UserGroup(user_id=analyst.id, group_id=existing_group.id)
        db.add(new_link)
        db.commit()
        db.refresh(existing_group)

        return {
            "db_data": serialize_db_group(existing_group),
            "vk_data": vk_info
        }
    else:
        # Если в БД нет, создаем новую запись
        new_group = models.Group(
            vk_group_id=vk_info["id"],
            name=vk_info.get("name"),
            screen_name=vk_info.get("screen_name")
        )
        db.add(new_group)
        db.commit()
        db.refresh(new_group)

        # Привязываем к аналитику
        new_link = models.UserGroup(user_id=analyst.id, group_id=new_group.id)
        db.add(new_link)
        db.commit()

        return {
            "db_data": serialize_db_group(new_group),
            "vk_data": vk_info
        }


@router.delete("/{analyst_id}/groups/{group_id}")
def unlink_group_from_analyst(
    token: str,
    analyst_id: int,
    group_id: int,
    db: Session = Depends(get_db)
):
    """
    DELETE /directors/{analyst_id}/groups/{group_id}?token=...
    Удаляем связь "analyst -> group". Саму группу не трогаем.
    """
    director = get_current_user(token, db)
    analyst = check_director_analyst_link(director, analyst_id, db)

    link = db.query(models.UserGroup).filter_by(user_id=analyst.id, group_id=group_id).first()
    if not link:
        raise HTTPException(status_code=404, detail="У этого аналитика нет такого паблика")

    db.delete(link)
    db.commit()

    return {"detail": f"Группа id={group_id} отвязана от аналитика {analyst.username}"}