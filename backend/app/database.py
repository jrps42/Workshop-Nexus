from sqlalchemy import inspect, text
from sqlmodel import SQLModel, Session as DatabaseSession, create_engine

from backend.app.models.workspace import Workspace

DATABASE_URL = "sqlite:///database/nexus.db"

engine = create_engine(DATABASE_URL, echo=True)


def migrate_database() -> None:
    """
    Apply small development migrations that SQLite cannot infer automatically.
    """

    inspector = inspect(engine)

    if "capture" not in inspector.get_table_names():
        return

    capture_columns = {
        column["name"]
        for column in inspector.get_columns("capture")
    }

    if "workspace_id" not in capture_columns:
        with engine.begin() as connection:
            connection.execute(
                text(
                    "ALTER TABLE capture "
                    "ADD COLUMN workspace_id CHAR(32)"
                )
            )


def create_db_and_tables() -> None:
    SQLModel.metadata.create_all(engine)
    migrate_database()


def get_database_session():
    with DatabaseSession(engine) as session:
        yield session