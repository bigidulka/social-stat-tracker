from fastapi import FastAPI
from contextlib import asynccontextmanager
from db.database import init_db
from routers import auth, groups, directors, vk_route
import logging

# Настройка логирования
logging.basicConfig(level=logging.DEBUG)
logging.getLogger('apscheduler').setLevel(logging.DEBUG)

app = FastAPI(
    title="VK Groups Stats API",
    version="1.0.0"
)

app.include_router(auth.router)
app.include_router(groups.router)
app.include_router(directors.router)
app.include_router(vk_route.router)

@app.get("/")
def root():
    return {"message": "Hello from VK Groups Stats API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)