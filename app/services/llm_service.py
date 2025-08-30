import ollama
import json
import re
from app.core.config import SYSTEM_RULES

class LLMEngine:
    def __init__(self, model: str = "phi3:mini"):
        self.model = model

    def _extract_json(self, response: str):
        response = response.strip()
        response = re.sub(r"^```[a-zA-Z]*", "", response)
        response = re.sub(r"```$", "", response)

        match = re.search(r"\[.*\]", response, re.DOTALL)
        if not match:
            raise ValueError(f"Couldn't find valid JSON in response:\n{response}")
        clean_json = match.group(0)
        return json.loads(clean_json)

    def correct_text(self, ocr_text: str, stream: bool = False):
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
            return self._extract_json(response)
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON response: {response}") from e
