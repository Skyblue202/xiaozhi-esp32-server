#!/bin/bash
CONFIG=/app/data/.config.yaml
sed -i "s|__GROQ_API_KEY__|${GROQ_API_KEY}|g" "$CONFIG"
sed -i "s|__DEEPSEEK_API_KEY__|${DEEPSEEK_API_KEY}|g" "$CONFIG"
rm -f /etc/nginx/sites-enabled/default
python app.py &
nginx -t && nginx -g "daemon off;"
