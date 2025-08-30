from app.services.llm_service import LLMEngine
from app.services.ocr_service import SuryaOCREngine
from io import BytesIO
from PIL import Image

class PrescriptionPipeline:
    def __init__(self, model="phi3:mini"):
        self.llm = LLMEngine(model=model)
        self.ocr = SuryaOCREngine()

    def process_bytes(self, image_bytes: bytes):
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
        raw_text = self.ocr.extract_text(image)         # OCR text retrieval
        structured = self.llm.correct_text(raw_text)    # Text correction by LLM
        return structured