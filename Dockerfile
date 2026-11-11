FROM python:3.10-slim

# 1. Instalamos TODAS las dependencias del sistema necesarias.
# Incluimos build-essential para compilar, y libgomp1/libgl1 para PyTorch y visión.
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libopus0 \
    git \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Instalamos la versión ligera de PyTorch (solo CPU) para evitar descargar GBs de NVIDIA.
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu

# 3. Copiamos e instalamos los requerimientos del proyecto.
COPY main/xiaozhi-server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copiamos el resto del código del servidor.
COPY main/xiaozhi-server/ .

EXPOSE 8000

# 5. Comando de inicio.
CMD ["python", "app.py"]
