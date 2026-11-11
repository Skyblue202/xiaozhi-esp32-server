FROM python:3.10-slim

# Instalamos Nginx y las dependencias
RUN apt-get update && apt-get install -y \
    ffmpeg libopus0 git wget build-essential libgl1 libglib2.0-0 libgomp1 nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY main/xiaozhi-server/ .

# Descargamos el modelo de voz
RUN mkdir -p models/SenseVoiceSmall && \
    wget -q https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt -O models/SenseVoiceSmall/model.pt

# Evitamos que intente descargar de internet
ENV HF_HUB_OFFLINE=1
ENV TRANSFORMERS_OFFLINE=1

# Instalamos dependencias de Python
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# Configuramos Nginx (escucha en el puerto 80 y reparte el tráfico)
RUN echo 'server { \
    listen 80; \
    location /xiaozhi/ota/ { \
        proxy_pass http://127.0.0.1:8003; \
        proxy_set_header Host $host; \
    } \
    location / { \
        proxy_pass http://127.0.0.1:8000; \
        proxy_http_version 1.1; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
        proxy_set_header Host $host; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Script para iniciar Python y Nginx al mismo tiempo
RUN echo '#!/bin/bash\n\
python app.py &\n\
nginx -g "daemon off;"' > /start.sh && chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
