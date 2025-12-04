#!/bin/bash
set -e

# Si quieres que el backend use otro puerto, establece SERVER_PORT antes de ejecutar
# Spring Boot respeta la variable de entorno SERVER_PORT.

# Arranca el backend en background
java -Xms256m -Xmx512m -jar /app/app.jar &

# Generar archivo de configuración runtime para el frontend
# Variables esperadas:
# - BACKEND_API_URL -> URL pública del backend (ej: https://api-ecomarket.onrender.com/ecomarket/api)
# Si no está definida, se usará el valor por defecto hacia localhost
BACKEND_API_URL=${BACKEND_API_URL:-http://127.0.0.1:8080/ecomarket/api}
echo "/* Runtime config */" > /var/www/html/env.js
echo "window.__env = { apiUrl: '${BACKEND_API_URL}' };" >> /var/www/html/env.js

# Espera un breve periodo para que el backend empiece (opcional)
sleep 2

# Arranca nginx en primer plano
nginx -g 'daemon off;'
