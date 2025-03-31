# main.py (или auth_routes.py — где роуты авторизации)
from fastapi import FastAPI, APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from datetime import datetime, timedelta
import jwt
import random
import string
import uuid

from db.database import SessionLocal, engine, Base
from db import models

from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

Base.metadata.create_all(bind=engine)

SECRET_KEY = "SUPER_SECRET_KEY_CHANGE_ME"  # Хранить в конфиге
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
router = APIRouter(prefix="/auth", tags=["auth"])


def create_access_token(data: dict, expires_delta: timedelta):
    to_encode = data.copy()
    expire = datetime.utcnow() + expires_delta
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def generate_unique_code() -> str:
    return str(uuid.uuid4())[:8]

@router.post("/register")
def register_user(request_data: dict = Body(...), db: Session = Depends(get_db)):
    username = request_data.get("username")
    password = request_data.get("password")
    confirm_password = request_data.get("confirm_password")
    role = request_data.get("role", "user")
    name = request_data.get("name", None)
    telegram = request_data.get("telegram", None)

    if not username or not password or not confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Необходимо передать username, password и confirm_password"
        )

    if password != confirm_password:
        raise HTTPException(status_code=400, detail="Пароли не совпадают")

    existing_user = db.query(models.User).filter(models.User.username == username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь с таким логином уже существует"
        )

    password_hash = pwd_context.hash(password)
    user_unique_code = generate_unique_code()

    new_user = models.User(
        username=username,
        password_hash=password_hash,
        role=role,
        name=name,
        telegram=telegram,
        unique_code=user_unique_code
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {
        "id": new_user.id,
        "username": new_user.username,
        "role": new_user.role,
        "name": new_user.name,
        "telegram": new_user.telegram,
        "date_of_registration": new_user.date_of_registration,
        "unique_code": new_user.unique_code
    }

@router.post("/login")
def login(request_data: dict = Body(...), db: Session = Depends(get_db)):
    username = request_data.get("username")
    password = request_data.get("password")

    if not username or not password:
        raise HTTPException(status_code=400, detail="Необходимо передать username и password")

    user = db.query(models.User).filter(models.User.username == username).first()
    if not user or not pwd_context.verify(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Неверные учётные данные")

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "role": user.role},
        expires_delta=access_token_expires
    )
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }

@router.get("/me")
def get_current_user_data(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Неверный или истёкший токен")

    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    return {
        "id": user.id,
        "username": user.username,
        "role": user.role,
        "name": user.name,
        "telegram": user.telegram,
        "unique_code": user.unique_code,
        "date_of_registration": user.date_of_registration
    }

@router.post("/forgot-password")
def forgot_password(request_data: dict = Body(...), db: Session = Depends(get_db)):
    username = request_data.get("username")
    if not username:
        raise HTTPException(status_code=400, detail="Необходимо передать username")

    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    new_pass = ''.join(random.choices(string.ascii_letters + string.digits, k=8))
    user.password_hash = pwd_context.hash(new_pass)
    db.commit()

    return {"detail": "Пароль сброшен", "new_password": new_pass}

@router.put("/update-profile")
def update_profile(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
    request_data: dict = Body(...)
):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Токен недействителен")

    user = db.query(models.User).filter_by(username=username).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")

    new_name = request_data.get("name")
    new_telegram = request_data.get("telegram")

    if new_name is not None:
        user.name = new_name
    if new_telegram is not None:
        user.telegram = new_telegram

    db.commit()
    db.refresh(user)

    return {
        "id": user.id,
        "username": user.username,
        "role": user.role,
        "name": user.name,
        "telegram": user.telegram,
        "unique_code": user.unique_code,
        "date_of_registration": user.date_of_registration
    }
