from sqlmodel import SQLModel, create_engine, Session as DatabaseSession

DATABASE_URL = "sqlite:///database/nexus.db"

engine = create_engine(DATABASE_URL, echo=True)


def create_db_and_tables():
    SQLModel.metadata.create_all(engine)


def get_database_session():
    with DatabaseSession(engine) as session:
        yield session