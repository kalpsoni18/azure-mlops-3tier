from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import psycopg2, os, datetime

app = FastAPI(title="MLOps 3-Tier API")

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/")
def root():
    return {"status": "ok", "service": "backend-api", "timestamp": str(datetime.datetime.utcnow())}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.get("/api/info")
def info():
    return {
        "app": "Azure MLOps 3-Tier",
        "version": "1.0.0",
        "environment": os.getenv("ENVIRONMENT", "dev"),
        "database": os.getenv("DB_HOST", "not configured")
    }

@app.get("/api/predictions")
def predictions():
    return {
        "model": "iris-classifier-v1",
        "predictions": [
            {"id": 1, "input": [5.1, 3.5, 1.4, 0.2], "output": "setosa", "confidence": 0.98},
            {"id": 2, "input": [6.7, 3.0, 5.2, 2.3], "output": "virginica", "confidence": 0.95},
            {"id": 3, "input": [5.8, 2.7, 4.1, 1.0], "output": "versicolor", "confidence": 0.91},
        ]
    }
