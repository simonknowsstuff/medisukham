import ollama
import json
from app.core.config import SYSTEM_RULES

class LLMEngine:
    def __init__(self, model: str = "phi3:mini"):
        self.model = model

    def correct_text(self, ocr_text: str, stream: bool = False) -> str:
        messages = [
            {"role": "system", "content": SYSTEM_RULES},
            {"role": "user", "content": f"OCR Text:\n{ocr_text}\n\nReturn only the cleaned medicine data."}
        ]

        response = ""
        if stream:
            out = []
            for chunk in ollama.chat(
                    model=self.model,
                    messages=messages,
                    stream=True,
                    options={"temperature": 0.1, "num_ctx": 4096}
            ):
                piece = chunk.get("message", {}).get("content", "")
                print(piece, end="", flush=True)
                out.append(piece)
            print()
            response = "".join(out)
        else:
            resp = ollama.chat(
                model=self.model,
                messages=messages,
                options={"temperature": 0.1, "num_ctx": 4096}
            )
            response = resp["message"]["content"]

        try:
            return json.loads(response)
        except:
            start = response.find("{")
            end = response.find("}")
            return json.loads(response[start:end])
