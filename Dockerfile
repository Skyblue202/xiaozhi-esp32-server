FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    ffmpeg \
    libopus0 \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY main/xiaozhi-server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main/xiaozhi-server/ .

EXPOSE 8000

CMD ["python", "app.py"]
