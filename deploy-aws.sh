#!/bin/bash

# =============================================================================
# EcoMarket - Script de Despliegue AWS
# =============================================================================

set -e  # Exit on any error

echo "🚀 INICIANDO DESPLIEGUE DE ECOMARKET EN AWS"
echo "============================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# 1. VERIFICACIONES PRE-DESPLIEGUE
# =============================================================================

log "Verificando prerequisitos..."

# Verificar Docker
if ! command -v docker &> /dev/null; then
    error "Docker no está instalado. Instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# Verificar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose no está instalado. Instalando..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

log "✅ Docker y Docker Compose verificados"

# =============================================================================
# 2. CONFIGURACIÓN DE VARIABLES DE ENTORNO
# =============================================================================

log "Configurando variables de entorno..."

# Generar JWT Secret si no existe
if [ -z "$JWT_SECRET" ]; then
    warn "JWT_SECRET no configurado. Generando uno nuevo..."
    export JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
    echo "JWT_SECRET=$JWT_SECRET" >> .env
fi

# Configurar variables por defecto
cat > .env << EOF
# Backend Configuration
SPRING_PROFILES_ACTIVE=prod
JWT_SECRET=$JWT_SECRET
DB_HOST=db
DB_PORT=5432
DB_NAME=ecomarket
DB_USERNAME=ecomarket_user
DB_PASSWORD=ecomarket_secure_password_2024
CORS_ORIGINS=http://localhost,https://your-domain.com

# Database Configuration
POSTGRES_DB=ecomarket
POSTGRES_USER=ecomarket_user
POSTGRES_PASSWORD=ecomarket_secure_password_2024

# Frontend Configuration
BACKEND_URL=http://backend:8080
EOF

log "✅ Variables de entorno configuradas"

# =============================================================================
# 3. CONSTRUCCIÓN DE IMÁGENES
# =============================================================================

log "Construyendo imágenes Docker..."

# Construir imagen del backend
log "Construyendo backend..."
cd backend-v2
docker build -t ecomarket-backend:latest .
cd ..

# Construir imagen del frontend
log "Construyendo frontend..."
cd frontend-angular
docker build -t ecomarket-frontend:latest .
cd ..

log "✅ Imágenes construidas exitosamente"

# =============================================================================
# 4. DESPLIEGUE CON DOCKER COMPOSE
# =============================================================================

log "Desplegando aplicación..."

# Detener contenedores existentes
docker-compose down 2>/dev/null || true

# Limpiar volúmenes si es necesario (opcional)
# docker-compose down -v

# Iniciar servicios
docker-compose up -d

log "✅ Servicios iniciados"

# =============================================================================
# 5. VERIFICACIONES POST-DESPLIEGUE
# =============================================================================

log "Ejecutando verificaciones de salud..."

# Esperar que los servicios se inicien
sleep 30

# Función para verificar salud de un servicio
check_health() {
    local service=$1
    local url=$2
    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s $url > /dev/null; then
            log "✅ $service está funcionando"
            return 0
        fi
        warn "Intento $attempt/$max_attempts - $service no responde..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    error "❌ $service no está respondiendo después de $max_attempts intentos"
    return 1
}

# Verificar base de datos
log "Verificando base de datos..."
if docker exec $(docker-compose ps -q db) pg_isready -U ecomarket_user -d ecomarket; then
    log "✅ Base de datos PostgreSQL funcionando"
else
    error "❌ Base de datos no está respondiendo"
    exit 1
fi

# Verificar backend
log "Verificando backend..."
check_health "Backend" "http://localhost:8080/ecomarket/api/health" || exit 1

# Verificar frontend
log "Verificando frontend..."
check_health "Frontend" "http://localhost/health" || exit 1

# Verificar imágenes del slider
log "Verificando imágenes del slider..."
check_health "Slider Image 1" "http://localhost:8080/ecomarket/api/images/slide1.png" || warn "Slider image 1 no accesible"
check_health "Slider Image 2" "http://localhost:8080/ecomarket/api/images/slide2.jpg" || warn "Slider image 2 no accesible"

# =============================================================================
# 6. INFORMACIÓN DE ACCESO
# =============================================================================

log "🎉 DESPLIEGUE COMPLETADO EXITOSAMENTE"
echo "====================================="
echo
echo -e "${BLUE}📱 INFORMACIÓN DE ACCESO:${NC}"
echo "Frontend: http://localhost"
echo "Backend API: http://localhost:8080/ecomarket/api"
echo "Base de datos: localhost:5432"
echo
echo -e "${BLUE}👥 USUARIOS DE PRUEBA:${NC}"
echo "Administrador: admin / admin123"
echo "Usuario: user / user123"
echo
echo -e "${BLUE}🔧 COMANDOS ÚTILES:${NC}"
echo "Ver logs: docker-compose logs -f [service]"
echo "Reiniciar: docker-compose restart [service]"
echo "Parar: docker-compose down"
echo "Estado: docker-compose ps"
echo
echo -e "${BLUE}🌐 PRÓXIMOS PASOS PARA PRODUCCIÓN:${NC}"
echo "1. Configurar dominio DNS"
echo "2. Instalar certificado SSL"
echo "3. Configurar backup automático"
echo "4. Configurar monitoreo"
echo
echo -e "${GREEN}✅ EcoMarket está funcionando correctamente!${NC}"

# =============================================================================
# 7. OPCIONAL: ABRIR BROWSER
# =============================================================================

if command -v xdg-open &> /dev/null; then
    log "Abriendo aplicación en el navegador..."
    xdg-open http://localhost
elif command -v open &> /dev/null; then
    log "Abriendo aplicación en el navegador..."
    open http://localhost
fi

log "🎯 Despliegue completado. ¡EcoMarket está listo para usar!"