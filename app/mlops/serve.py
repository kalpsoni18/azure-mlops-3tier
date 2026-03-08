from fastapi import FastAPI
import pickle, json, os
import numpy as np

app = FastAPI(title="MLOps Model Server")

# Load model at startup
model = None
metrics = {}

@app.on_event("startup")
def load_model():
    global model, metrics
    model_path = "models/iris_model.pkl"
    metrics_path = "models/metrics.json"
    if os.path.exists(model_path):
        with open(model_path, "rb") as f:
            model = pickle.load(f)
        print("✅ Model loaded")
    if os.path.exists(metrics_path):
        with open(metrics_path) as f:
            metrics = json.load(f)

@app.get("/")
def root():
    return {"service": "mlops-model-server", "status": "running"}

@app.get("/health")
def health():
    return {"status": "healthy", "model_loaded": model is not None}

@app.get("/model/info")
def model_info():
    return {
        "model": "iris-classifier-v1",
        "algorithm": "RandomForest",
        "metrics": metrics
    }

@app.post("/predict")
def predict(data: dict):
    if model is None:
        return {"error": "Model not loaded"}
    features = np.array(data["features"]).reshape(1, -1)
    prediction = model.predict(features)[0]
    proba = model.predict_proba(features)[0]
    classes = ["setosa", "versicolor", "virginica"]
    return {
        "prediction": classes[prediction],
        "confidence": float(max(proba)),
        "probabilities": {c: float(p) for c, p in zip(classes, proba)}
    }
