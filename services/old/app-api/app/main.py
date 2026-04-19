import os
import time
from contextlib import asynccontextmanager

import pymysql
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "3306"))
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

DB_CONNECT_RETRIES = int(os.environ.get("DB_CONNECT_RETRIES", "30"))
DB_CONNECT_RETRY_DELAY = float(os.environ.get("DB_CONNECT_RETRY_DELAY", "2"))

app_state = {
    "db_ready": False,
}


def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        autocommit=True,
        cursorclass=pymysql.cursors.DictCursor,
    )


def wait_for_db():
    last_error = None

    for attempt in range(1, DB_CONNECT_RETRIES + 1):
        try:
            conn = get_connection()
            with conn.cursor() as cur:
                cur.execute("SELECT 1 AS ok;")
                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS items (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                    """
                )
            conn.close()
            return
        except Exception as exc:
            last_error = exc
            print(
                f"[startup] DB connection attempt {attempt}/{DB_CONNECT_RETRIES} failed: {exc}",
                flush=True,
            )
            if attempt < DB_CONNECT_RETRIES:
                time.sleep(DB_CONNECT_RETRY_DELAY)

    raise RuntimeError(
        f"Database was not ready after {DB_CONNECT_RETRIES} attempts. Last error: {last_error}"
    )


class ItemCreate(BaseModel):
    name: str


@asynccontextmanager
async def lifespan(app: FastAPI):
    wait_for_db()
    app_state["db_ready"] = True
    print("[startup] Database ready, schema ensured.", flush=True)
    yield
    app_state["db_ready"] = False


app = FastAPI(lifespan=lifespan)


@app.get("/healthz")
def healthz():
    if not app_state["db_ready"]:
        raise HTTPException(status_code=503, detail="app started but db not ready")

    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT 1 AS ok;")
            result = cur.fetchone()
        conn.close()
        return {
            "status": "ok",
            "db": "ok",
            "db_host": DB_HOST,
            "db_name": DB_NAME,
            "ping": result["ok"],
        }
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"db check failed: {exc}")


@app.post("/items")
def create_item(item: ItemCreate):
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO items (name) VALUES (%s)",
                (item.name,),
            )
            item_id = cur.lastrowid
        conn.close()
        return {"id": item_id, "name": item.name}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"insert failed: {exc}")


@app.get("/items")
def list_items():
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, created_at FROM items ORDER BY id ASC"
            )
            rows = cur.fetchall()
        conn.close()
        return rows
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"query failed: {exc}")
