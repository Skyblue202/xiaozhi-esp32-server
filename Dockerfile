FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    ffmpeg \
    libopus0 \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalamos la versión ligera de PyTorch (solo CPU) para evitar descargar 
# los gigas de controladores de NVIDIA y triton que no sirven aquí.
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

COPY main/xiaozhi-server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main/xiaozhi-server/ .

EXPOSE 8000

CMD ["python", "app.py"]
