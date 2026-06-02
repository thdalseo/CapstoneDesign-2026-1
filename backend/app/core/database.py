import os
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

is_sqlite = SQLALCHEMY_DATABASE_URL.startswith("sqlite")
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False} if is_sqlite else {},
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_schema_compatibility():
    """Preserve local DB data while adding columns introduced after table creation."""
    inspector = inspect(engine)
    if "users" not in inspector.get_table_names():
        return

    existing_columns = {column["name"] for column in inspector.get_columns("users")}
    user_column_migrations = {
        "weight_purpose": "INTEGER NOT NULL DEFAULT 25",
        "weight_interests": "INTEGER NOT NULL DEFAULT 20",
        "weight_language": "INTEGER NOT NULL DEFAULT 18",
        "weight_personality": "INTEGER NOT NULL DEFAULT 17",
        "weight_major": "INTEGER NOT NULL DEFAULT 8",
        "weight_year": "INTEGER NOT NULL DEFAULT 7",
        "weight_nationality": "INTEGER NOT NULL DEFAULT 5",
    }

    with engine.begin() as connection:
        for column_name, column_sql in user_column_migrations.items():
            if column_name not in existing_columns:
                connection.execute(
                    text(f"ALTER TABLE users ADD COLUMN {column_name} {column_sql}")
                )
