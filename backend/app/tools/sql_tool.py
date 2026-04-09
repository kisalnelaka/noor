from langchain.tools import tool
from app.db.database import engine, SessionLocal, DATABASE_URL
import pandas as pd

@tool("query_sql_database")
def query_sql_database(query: str, params: dict = None) -> str:
    """
    Executes a SELECT query against the local SQLite Aura database.
    Input must be a valid SQLite query.
    Supports optional params dict for coordinate-based proximity math.
    """
    try:
        from sqlalchemy import text
        with engine.connect() as conn:
            df = pd.read_sql(text(query), conn, params=params)
        return df.to_json(orient="records")
    except Exception as e:
        return f"Error executing SQL: {str(e)}"
