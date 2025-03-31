# directors_routes.py
from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from db.database import SessionLocal
from db import models
import jwt

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
