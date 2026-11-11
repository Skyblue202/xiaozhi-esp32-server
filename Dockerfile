FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    ffmpeg libopus0 git wget build-essential libgl1 libglib2.0-0 libgomp1 nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY main/xiaozhi-server/ .

RUN mkdir -p models/SenseVoiceSmall && \
    wget -q https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt -O models/SenseVoiceSmall/model.pt

ENV HF_HUB_OFFLINE=1
ENV TRANSFORMERS_OFFLINE=1

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# Configuración de Nginx optimizada
RUN echo 'server { \
    listen 80; \
    location /xiaozhi/ota/ { \
        proxy_pass http://127.0.0.1:8003/xiaozhi/ota/; \
        proxy_set_header Host $host; \
    } \
    location /xiaozhi/ota { \
        proxy_pass http://127.0.0.1:8003/xiaozhi/ota; \
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

RUN echo '#!/bin/bash\n\
python app.py &\n\
nginx -g "daemon off;"' > /start.sh && chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
