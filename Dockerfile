FROM python:3.10-slim

# 1. Instalamos dependencias del sistema y Nginx
RUN apt-get update && apt-get install -y \
    ffmpeg libopus0 git wget build-essential libgl1 libglib2.0-0 libgomp1 nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copiamos el código del servidor
COPY main/xiaozhi-server/ .

# 3. Descargamos el modelo de voz desde ModelScope
RUN mkdir -p models/SenseVoiceSmall && \
    wget -q https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt -O models/SenseVoiceSmall/model.pt

# 4. Evitamos descargas en tiempo de ejecución
ENV HF_HUB_OFFLINE=1
ENV TRANSFORMERS_OFFLINE=1

# 5. Instalamos PyTorch (CPU) y los requerimientos
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# 6. Configuramos Nginx para redirigir el tráfico al puerto correcto
RUN echo 'server { \
    listen 80; \
    location /xiaozhi/ota { \
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

# 7. Script para iniciar Python y Nginx al mismo tiempo
RUN echo '#!/bin/bash\n\
python app.py &\n\
nginx -g "daemon off;"' > /start.sh && chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
