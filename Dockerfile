FROM python:3.10-slim

# 1. Dependencias del sistema y Nginx
RUN apt-get update && apt-get install -y \
    ffmpeg libopus0 git wget build-essential libgl1 libglib2.0-0 libgomp1 nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Código del servidor
COPY main/xiaozhi-server/ .

# 3. Modelo de voz desde ModelScope
RUN mkdir -p models/SenseVoiceSmall && \
    wget -q https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt -O models/SenseVoiceSmall/model.pt

# 4. Sin descargas en tiempo de ejecución
ENV HF_HUB_OFFLINE=1
ENV TRANSFORMERS_OFFLINE=1

# 5. PyTorch CPU + requerimientos
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# 6. Quitar el sitio por defecto de Debian y poner el nuestro
RUN rm -f /etc/nginx/sites-enabled/default && \
    echo 'server { \
    listen 80 default_server; \
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
        proxy_read_timeout 3600s; \
    } \
}' > /etc/nginx/conf.d/default.conf

# 7. Iniciar Python y Nginx juntos
RUN printf '#!/bin/bash\npython app.py &\nnginx -g "daemon off;"\n' > /start.sh && chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
