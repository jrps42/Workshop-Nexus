from fastapi import FastAPI

from backend.app.api.captures import router as captures_router
from backend.app.api.sessions import router as sessions_router
from backend.app.database import create_db_and_tables

from backend.app.api.workspaces import router as workspaces_router

app = FastAPI(title="Workshop Nexus")


@app.on_event("startup")
def on_startup():
    create_db_and_tables()


app.include_router(sessions_router)
app.include_router(captures_router)
app.include_router(workspaces_router)


@app.get("/health")
def health():
    return {"status": "ok", "project": "Workshop Nexus"}


@app.get("/nexus")
def nexus_identity():
    return {
        "name": "Workshop Nexus",
        "codename": "Genesis",
        "version": "0.0.1",
        "epoch": "I",
        "status": "Online",
        "architecture": "API-first",
        "knowledge_engine": "Inactive",
        "database": "SQLite",
        "modules": ["sessions", "captures"],
    }