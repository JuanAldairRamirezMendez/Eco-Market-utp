#!/bin/bash
set -e

# Si quieres que el backend use otro puerto, establece SERVER_PORT antes de ejecutar
# Spring Boot respeta la variable de entorno SERVER_PORT.

# Arranca el backend en background
java -Xms256m -Xmx512m -jar /app/app.jar &

# Espera un breve periodo para que el backend empiece (opcional)
sleep 2

# Arranca nginx en primer plano
nginx -g 'daemon off;'
