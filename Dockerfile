FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    ffmpeg libopus0 git wget build-essential libgl1 libglib2.0-0 libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiamos el código primero
COPY main/xiaozhi-server/ .

# Descargamos el modelo JUSTO DESPUÉS de copiar el código, en la ruta exacta
RUN mkdir -p models/SenseVoiceSmall && \
    wget -q https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt -O models/SenseVoiceSmall/model.pt

# Evitamos que el servidor intente descargar de nuevo
ENV HF_HUB_OFFLINE=1
ENV TRANSFORMERS_OFFLINE=1

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

EXPOSE 8000
CMD ["python", "app.py"]
