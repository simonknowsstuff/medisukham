from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.pipeline_service import PrescriptionPipeline
from app.schemas.prescription import PrescriptionResponse

router = APIRouter()
pipeline = PrescriptionPipeline()

@router.post("/", response_model=PrescriptionResponse)
async def process_prescription(file: UploadFile = File(...)):
    try:
        image_bytes = await file.read()
        result = pipeline.process_bytes(image_bytes)
        return {"items": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))