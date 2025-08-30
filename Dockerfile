FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y libgl1 curl

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Set workdir
WORKDIR /app

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code
COPY . .

# Expose API port
EXPOSE 7860

# Run FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]