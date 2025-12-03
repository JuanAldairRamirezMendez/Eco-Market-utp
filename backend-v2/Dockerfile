# Etapa de construcción
FROM maven:3.9-eclipse-temurin-22 AS build
WORKDIR /app

# Copiar archivos del proyecto
COPY pom.xml .
COPY src ./src

# Compilar la aplicación con configuración de red optimizada
RUN mvn clean package -DskipTests \
    -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.retryHandler.count=3 \
    -Dmaven.wagon.http.pool=false \
    -Dhttp.maxConnections=10

# Etapa de producción
FROM eclipse-temurin:22-jre-jammy
WORKDIR /app

# Instalar wget y crear usuario no-root
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*
RUN groupadd -r ecomarket && useradd -r -g ecomarket ecomarket

# Copiar el JAR compilado
COPY --from=build /app/target/backend-v2-1.0.0.jar app.jar

# Crear directorio de uploads
RUN mkdir -p /app/uploads && chown -R ecomarket:ecomarket /app

# Cambiar al usuario no-root
USER ecomarket

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/ecomarket/api/health || exit 1

CMD ["java", "-jar", "app.jar"]
