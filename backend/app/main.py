from fastapi import FastAPI

app = FastAPI(title="Workshop Nexus")

@app.get("/health")
def health():
    return {"status": "ok", "project": "Workshop Nexus"}
