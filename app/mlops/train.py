"""
MLOps Pipeline — Iris Classifier
Trains a Random Forest model, logs metrics, saves model artifact
"""
import json, os, pickle
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

def train():
    print("🚀 Starting MLOps training pipeline...")
    
    # Load data
    iris = load_iris()
    X, y = iris.data, iris.target
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Train
    params = {"n_estimators": 100, "max_depth": 5, "random_state": 42}
    model = RandomForestClassifier(**params)
    model.fit(X_train, y_train)
    
    # Evaluate
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"✅ Model trained — Accuracy: {accuracy:.4f}")
    print(classification_report(y_test, y_pred, target_names=iris.target_names))
    
    # Save model
    os.makedirs("models", exist_ok=True)
    with open("models/iris_model.pkl", "wb") as f:
        pickle.dump(model, f)
    
    # Save metrics
    metrics = {
        "accuracy": accuracy,
        "n_estimators": params["n_estimators"],
        "max_depth": params["max_depth"],
        "training_samples": len(X_train),
        "test_samples": len(X_test),
        "classes": list(iris.target_names)
    }
    with open("models/metrics.json", "w") as f:
        json.dump(metrics, f, indent=2)
    
    print(f"📦 Model saved to models/iris_model.pkl")
    print(f"📊 Metrics saved to models/metrics.json")
    return metrics

if __name__ == "__main__":
    train()
