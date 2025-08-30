from PIL import Image
from surya.foundation import FoundationPredictor
from surya.recognition import RecognitionPredictor
from surya.detection import DetectionPredictor

class SuryaOCREngine:
    def __init__(self):
        self.foundation = FoundationPredictor()
        self.recognition = RecognitionPredictor(self.foundation)
        self.detection = DetectionPredictor()

    def extract_text(self, image: Image.Image) -> str:
        results = self.recognition([image], det_predictor=self.detection)
        lines = []
        for page in results:
            for tl in page.text_lines:
                lines.append(tl.text)
        return "\n".join(lines)
