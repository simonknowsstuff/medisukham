from fastapi import FastAPI
from app.api.v1.prescriptions import router

app = FastAPI()
app.include_router(router)

