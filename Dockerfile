# Dockerfile multi-stage para construir frontend (Angular) y backend (Maven/Java)
# y servir el frontend con Nginx mientras se ejecuta el backend en la misma imagen.

### 1) Build del frontend (Node)
FROM node:18-alpine AS frontend-build
WORKDIR /frontend
COPY frontend-angular/package*.json ./
COPY frontend-angular/ .
RUN npm ci --legacy-peer-deps || npm install
RUN npm run build -- --configuration production || npm run build

### 2) Build del backend (Maven + JDK)
FROM maven:3.8.8-eclipse-temurin-17 AS backend-build
WORKDIR /backend
COPY backend-v2/ ./
RUN mvn -B -DskipTests package

### 3) Imagen final: Java (Temurin) + Nginx
# Usamos Eclipse Temurin para mayor compatibilidad con mirrors
FROM eclipse-temurin:17-jdk

# Instala nginx
RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia el .jar del backend (se renombra a app.jar)
COPY --from=backend-build /backend/target/*.jar /app/app.jar

# Copia los assets build del frontend al directorio de nginx (copiando el contenido)
RUN mkdir -p /var/www/html
COPY --from=frontend-build /frontend/dist/. /var/www/html/

# Copia la configuración de nginx (servir SPA y proxy /api/ al backend local)
COPY docker/nginx-default.conf /etc/nginx/conf.d/default.conf

# Copia el script de inicio
COPY docker/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["/start.sh"]
