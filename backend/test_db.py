from sqlalchemy import inspect, text
from sqlalchemy.exc import SQLAlchemyError

from app.core.database import Base, engine, ensure_schema_compatibility
from app.models import user  # noqa: F401 - register SQLAlchemy models on Base.metadata

EXPECTED_TABLES = [
    "users",
    "user_interests",
    "user_exchange_purposes",
    "user_personalities",
    "user_languages",
    "matches",
    "chat_rooms",
    "chat_messages",
    "chat_room_reads",
    "notifications",
    "help_posts",
    "help_helpers",
    "language_exchange_posts",
    "email_verifications",
]


def main():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        print("[OK] Database connection succeeded.")

        Base.metadata.create_all(bind=engine)
        ensure_schema_compatibility()
        print("[OK] SQLAlchemy tables were created or already existed.")

        inspector = inspect(engine)
        existing_tables = set(inspector.get_table_names())
        missing_tables = [table for table in EXPECTED_TABLES if table not in existing_tables]

        if missing_tables:
            print("[FAIL] Missing tables:")
            for table in missing_tables:
                print(f"  - {table}")
            return

        print("[OK] All expected tables exist.\n")
        for table_name in EXPECTED_TABLES:
            columns = inspector.get_columns(table_name)
            foreign_keys = inspector.get_foreign_keys(table_name)
            unique_constraints = inspector.get_unique_constraints(table_name)

            print(f"[{table_name}]")
            print("  columns:", ", ".join(column["name"] for column in columns))

            if foreign_keys:
                fk_names = [fk.get("name") or "unnamed_fk" for fk in foreign_keys]
                print("  foreign keys:", ", ".join(fk_names))

            if unique_constraints:
                uq_names = [uq.get("name") or "unnamed_unique" for uq in unique_constraints]
                print("  unique constraints:", ", ".join(uq_names))

        print("\n[DONE] DB model test completed successfully.")

    except SQLAlchemyError as error:
        print("[FAIL] Database model test failed.")
        print(error)


if __name__ == "__main__":
    main()
