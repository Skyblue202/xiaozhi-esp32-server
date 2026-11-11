FROM python:3.10-slim

# 1. Instalamos las dependencias del sistema (incluyendo wget)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libopus0 \
    git \
    wget \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Descargamos el modelo de voz desde ModelScope (más estable)
RUN mkdir -p /app/models/SenseVoiceSmall && \
    wget -q https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt -O /app/models/SenseVoiceSmall/model.pt

# 3. Instalamos la versión ligera de PyTorch (solo CPU)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu

# 4. Copiamos e instalamos los requerimientos
COPY main/xiaozhi-server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copiamos el resto del código del servidor
COPY main/xiaozhi-server/ .

EXPOSE 8000

# 6. Comando de inicio
CMD ["python", "app.py"]
