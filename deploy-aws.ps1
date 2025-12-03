# =============================================================================
# EcoMarket - Script de Despliegue AWS (PowerShell)
# =============================================================================

param(
    [switch]$SkipBuild = $false,
    [switch]$CleanVolumes = $false,
    [string]$Environment = "prod"
)

Write-Host "🚀 INICIANDO DESPLIEGUE DE ECOMARKET EN AWS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Función para logging con colores
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    switch ($Level) {
        "INFO" { Write-Host "[INFO] $Message" -ForegroundColor Green }
        "WARN" { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "TITLE" { Write-Host "$Message" -ForegroundColor Cyan }
    }
}

# =============================================================================
# 1. VERIFICACIONES PRE-DESPLIEGUE
# =============================================================================

Write-Log "Verificando prerequisitos..."

# Verificar Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Log "Docker no está instalado. Descarga desde: https://desktop.docker.com/" -Level "ERROR"
    exit 1
}

# Verificar Docker Compose
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Log "Docker Compose no está instalado. Viene incluido con Docker Desktop." -Level "ERROR"
    exit 1
}

Write-Log "✅ Docker y Docker Compose verificados"

# =============================================================================
# 2. CONFIGURACIÓN DE VARIABLES DE ENTORNO
# =============================================================================

Write-Log "Configurando variables de entorno..."

# Generar JWT Secret si no existe
$jwtSecret = $env:JWT_SECRET
if (-not $jwtSecret) {
    Write-Log "JWT_SECRET no configurado. Generando uno nuevo..." -Level "WARN"
    # Generar secret de 512 bits (64 bytes en base64)
    $bytes = [byte[]]::new(64)
    [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
    $jwtSecret = [Convert]::ToBase64String($bytes)
    $env:JWT_SECRET = $jwtSecret
}

# Crear archivo .env
$envContent = @"
# Backend Configuration
SPRING_PROFILES_ACTIVE=$Environment
JWT_SECRET=$jwtSecret
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
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8 -Force

Write-Log "✅ Variables de entorno configuradas"

# =============================================================================
# 3. CONSTRUCCIÓN DE IMÁGENES (OPCIONAL)
# =============================================================================

if (-not $SkipBuild) {
    Write-Log "Construyendo imágenes Docker..."

    # Construir imagen del backend
    Write-Log "Construyendo backend..."
    Set-Location backend-v2
    docker build -t ecomarket-backend:latest .
    Set-Location ..

    # Construir imagen del frontend
    Write-Log "Construyendo frontend..."
    Set-Location frontend-angular
    docker build -t ecomarket-frontend:latest .
    Set-Location ..

    Write-Log "✅ Imágenes construidas exitosamente"
} else {
    Write-Log "Saltando construcción de imágenes (usando cache existente)"
}

# =============================================================================
# 4. DESPLIEGUE CON DOCKER COMPOSE
# =============================================================================

Write-Log "Desplegando aplicación..."

# Detener contenedores existentes
try {
    docker-compose down 2>$null
    Write-Log "Contenedores anteriores detenidos"
} catch {
    Write-Log "No hay contenedores anteriores" -Level "WARN"
}

# Limpiar volúmenes si se especifica
if ($CleanVolumes) {
    Write-Log "Limpiando volúmenes..." -Level "WARN"
    docker-compose down -v
}

# Iniciar servicios
Write-Log "Iniciando servicios con Docker Compose..."
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Log "Error al iniciar servicios con Docker Compose" -Level "ERROR"
    exit 1
}

Write-Log "✅ Servicios iniciados"

# =============================================================================
# 5. VERIFICACIONES POST-DESPLIEGUE
# =============================================================================

Write-Log "Ejecutando verificaciones de salud..."

# Esperar que los servicios se inicien
Write-Log "Esperando que los servicios se inicialicen..."
Start-Sleep -Seconds 30

# Función para verificar salud de un servicio
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$MaxAttempts = 10
    )
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Log "✅ $ServiceName está funcionando"
                return $true
            }
        } catch {
            Write-Log "Intento $attempt/$MaxAttempts - $ServiceName no responde..." -Level "WARN"
            Start-Sleep -Seconds 10
        }
    }
    
    Write-Log "❌ $ServiceName no está respondiendo después de $MaxAttempts intentos" -Level "ERROR"
    return $false
}

# Verificar base de datos
Write-Log "Verificando base de datos..."
$dbContainerId = docker-compose ps -q db
if ($dbContainerId) {
    $dbCheck = docker exec $dbContainerId pg_isready -U ecomarket_user -d ecomarket
    if ($LASTEXITCODE -eq 0) {
        Write-Log "✅ Base de datos PostgreSQL funcionando"
    } else {
        Write-Log "❌ Base de datos no está respondiendo" -Level "ERROR"
        exit 1
    }
} else {
    Write-Log "❌ Contenedor de base de datos no encontrado" -Level "ERROR"
    exit 1
}

# Verificar backend
Write-Log "Verificando backend..."
if (-not (Test-ServiceHealth "Backend" "http://localhost:8080/ecomarket/api/health")) {
    Write-Log "Intentando verificar endpoint alternativo..." -Level "WARN"
    if (-not (Test-ServiceHealth "Backend" "http://localhost:8080/ecomarket/api/products")) {
        Write-Log "❌ Backend no está respondiendo" -Level "ERROR"
        # Mostrar logs para debugging
        Write-Log "Mostrando logs del backend:" -Level "WARN"
        docker-compose logs backend
        exit 1
    }
}

# Verificar frontend
Write-Log "Verificando frontend..."
if (-not (Test-ServiceHealth "Frontend" "http://localhost/health")) {
    Write-Log "Intentando verificar página principal..." -Level "WARN"
    if (-not (Test-ServiceHealth "Frontend" "http://localhost/")) {
        Write-Log "❌ Frontend no está respondiendo correctamente" -Level "ERROR"
        # Mostrar logs para debugging
        Write-Log "Mostrando logs del frontend:" -Level "WARN"
        docker-compose logs frontend
        exit 1
    }
}

# Verificar imágenes del slider
Write-Log "Verificando imágenes del slider..."
if (-not (Test-ServiceHealth "Slider Image 1" "http://localhost:8080/ecomarket/api/images/slide1.png")) {
    Write-Log "Slider image 1 no accesible" -Level "WARN"
}
if (-not (Test-ServiceHealth "Slider Image 2" "http://localhost:8080/ecomarket/api/images/slide2.jpg")) {
    Write-Log "Slider image 2 no accesible" -Level "WARN"
}

# =============================================================================
# 6. INFORMACIÓN DE ACCESO
# =============================================================================

Write-Log "🎉 DESPLIEGUE COMPLETADO EXITOSAMENTE" -Level "TITLE"
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📱 INFORMACIÓN DE ACCESO:" -ForegroundColor Blue
Write-Host "Frontend: http://localhost"
Write-Host "Backend API: http://localhost:8080/ecomarket/api"
Write-Host "Base de datos: localhost:5432"
Write-Host ""

Write-Host "👥 USUARIOS DE PRUEBA:" -ForegroundColor Blue
Write-Host "Administrador: admin / admin123"
Write-Host "Usuario: user / user123"
Write-Host ""

Write-Host "🔧 COMANDOS ÚTILES:" -ForegroundColor Blue
Write-Host "Ver logs: docker-compose logs -f [service]"
Write-Host "Reiniciar: docker-compose restart [service]"
Write-Host "Parar: docker-compose down"
Write-Host "Estado: docker-compose ps"
Write-Host ""

Write-Host "🌐 PRÓXIMOS PASOS PARA PRODUCCIÓN:" -ForegroundColor Blue
Write-Host "1. Configurar dominio DNS"
Write-Host "2. Instalar certificado SSL"
Write-Host "3. Configurar backup automático"
Write-Host "4. Configurar monitoreo"
Write-Host ""

Write-Host "✅ EcoMarket está funcionando correctamente!" -ForegroundColor Green

# =============================================================================
# 7. MOSTRAR ESTADO DE CONTENEDORES
# =============================================================================

Write-Log "Estado actual de contenedores:" -Level "TITLE"
docker-compose ps

# =============================================================================
# 8. OPCIONAL: ABRIR BROWSER
# =============================================================================

$openBrowser = Read-Host "¿Deseas abrir la aplicación en el navegador? (y/N)"
if ($openBrowser -match '^[Yy]') {
    Write-Log "Abriendo aplicación en el navegador..."
    Start-Process "http://localhost"
}

Write-Log "🎯 Despliegue completado. ¡EcoMarket está listo para usar!" -Level "TITLE"

# =============================================================================
# 9. EJEMPLO DE USO
# =============================================================================

Write-Host ""
Write-Host "EJEMPLOS DE USO DEL SCRIPT:" -ForegroundColor Magenta
Write-Host ".\deploy-aws.ps1                    # Despliegue completo"
Write-Host ".\deploy-aws.ps1 -SkipBuild         # Saltar construcción de imágenes"
Write-Host ".\deploy-aws.ps1 -CleanVolumes      # Limpiar volúmenes de datos"
Write-Host ".\deploy-aws.ps1 -Environment dev   # Usar perfil de desarrollo"