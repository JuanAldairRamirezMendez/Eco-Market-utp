# 🚀 Guía Completa de Despliegue AWS - EcoMarket

## 📋 Resumen Ejecutivo

**EcoMarket** está completamente preparado para despliegue en AWS con arquitectura completa de 3 capas:
- ✅ **Frontend Angular 18** con SSR y Nginx
- ✅ **Backend Spring Boot 3.3.0** con Java 22
- ✅ **Base de datos PostgreSQL** 
- ✅ **Almacenamiento S3** para imágenes
- ✅ **Contenedorización Docker** completa

---

## 🏗️ Arquitectura AWS

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION LOAD BALANCER                │
│                         (Port 80/443)                      │
└──────────────────┬──────────────────┬─────────────────────┘
                   │                  │
                   ▼                  ▼
        ┌─────────────────┐    ┌─────────────────┐
        │   EC2 Frontend  │    │   EC2 Backend   │
        │   Angular+Nginx │    │  Spring Boot    │
        │    (Port 80)    │    │   (Port 8080)   │
        └─────────────────┘    └─────────┬───────┘
                                         │
                                         ▼
                              ┌─────────────────┐
                              │   RDS PostgreSQL │
                              │    (Port 5432)   │
                              └─────────────────┘
                                         
        ┌─────────────────────────────────────────┐
        │              S3 Bucket                  │
        │        (Imágenes de productos)          │
        └─────────────────────────────────────────┘
```

---

## 🎯 OPCIÓN RÁPIDA: Despliegue con un Solo Comando

### Para Windows (PowerShell)
```powershell
# 1. Configurar S3
.\setup-s3.ps1 -BucketName "ecomarket-prod"

# 2. Cargar configuración
. .\aws-s3-config.ps1

# 3. Desplegar
.\deploy-aws.ps1
```

### Para Linux/Mac (Bash)
```bash
# 1. Configurar S3
chmod +x setup-s3.sh
./setup-s3.sh ecomarket-prod

# 2. Cargar configuración
source aws-s3-config.env

# 3. Desplegar
chmod +x deploy-aws.sh
./deploy-aws.sh
```

---

## 🎯 OPCIÓN COMPLETA: Plan de Despliegue Paso a Paso

### Fase 1: Preparación AWS (30 minutos)

#### 1.1 Configurar AWS CLI
```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
```

#### 1.2 Crear Instancia EC2
```bash
# Crear key pair
aws ec2 create-key-pair \
    --key-name ecomarket-key \
    --query 'KeyMaterial' \
    --output text > ecomarket-key.pem
chmod 400 ecomarket-key.pem

# Lanzar instancia
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --count 1 \
    --instance-type t3.medium \
    --key-name ecomarket-key \
    --security-groups default \
    --user-data file://user-data.sh
```

### Fase 2: Configurar S3 (15 minutos)

```powershell
# Ejecutar script de S3
.\setup-s3.ps1 -BucketName "ecomarket-prod-images"

# Cargar variables
. .\aws-s3-config.ps1
```

### Fase 3: Desplegar Aplicación (20 minutos)

#### En EC2:
```bash
# Instalar Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Subir código
scp -i ecomarket-key.pem -r . ec2-user@EC2-IP:/home/ec2-user/ecomarket/

# Desplegar
cd /home/ec2-user/ecomarket
docker-compose up -d
```

---

## 📊 Monitoreo y Verificación

### Health Checks
```bash
# Backend
curl http://EC2-IP:8080/ecomarket/api/health

# Frontend
curl http://EC2-IP/health

# Base de datos
docker exec postgres-container pg_isready

# S3
aws s3 ls s3://tu-bucket/
```

---

## 💰 Estimación de Costos

| Servicio | Configuración | Costo Mensual |
|----------|---------------|---------------|
| **EC2** | t3.medium | ~$30 USD |
| **RDS** | db.t3.micro | ~$12 USD |
| **S3** | 5GB | ~$1 USD |
| **Data Transfer** | 10GB | ~$1 USD |
| **Total** | | **~$44 USD/mes** |

---

## 🔧 Variables de Entorno Críticas

```bash
# JWT Secret (OBLIGATORIO cambiar en producción)
JWT_SECRET="nueva-clave-super-segura-512-bits"

# Base de datos
DB_HOST="tu-rds-endpoint.amazonaws.com"
DB_USERNAME="ecomarket_user"
DB_PASSWORD="password-super-seguro"

# S3
AWS_S3_ENABLED=true
AWS_S3_BUCKET="ecomarket-prod-images"
AWS_ACCESS_KEY_ID="tu-access-key"
AWS_SECRET_ACCESS_KEY="tu-secret-key"

# CORS
CORS_ORIGINS="https://tu-dominio.com,http://tu-ip-ec2"
```

---

## 🚨 Checklist Final

### ✅ Antes del Despliegue
- [ ] AWS CLI instalado y configurado
- [ ] Bucket S3 creado y configurado
- [ ] Variables de entorno configuradas
- [ ] Scripts de despliegue probados

### ✅ Durante el Despliegue
- [ ] EC2 instancia creada y funcionando
- [ ] Docker y Docker Compose instalados
- [ ] Código subido a EC2
- [ ] Contenedores desplegados

### ✅ Después del Despliegue
- [ ] Health checks funcionando
- [ ] Imágenes cargando desde S3
- [ ] Base de datos conectada
- [ ] Frontend accesible
- [ ] Usuarios de prueba funcionando

---

## 🔍 Troubleshooting

### Problema: Backend no arranca
```bash
# Ver logs
docker logs ecomarket-backend

# Verificar variables de entorno
docker exec ecomarket-backend env | grep -E "(JWT|DB|AWS)"
```

### Problema: Imágenes no cargan
```bash
# Verificar S3
aws s3 ls s3://tu-bucket/products/

# Verificar configuración
curl -I http://EC2-IP:8080/ecomarket/api/images/slide1.png
```

### Problema: Frontend no accesible
```bash
# Verificar Nginx
docker logs ecomarket-frontend

# Verificar puerto
netstat -tulpn | grep :80
```

---

## 🎉 URLs Finales

Una vez desplegado, tu aplicación estará disponible en:

- **Frontend**: `http://tu-ec2-ip/`
- **Backend API**: `http://tu-ec2-ip:8080/ecomarket/api/`
- **Usuarios de Prueba**:
  - Admin: `admin / admin123`
  - User: `user / user123`

---

## 🔄 Comandos de Mantenimiento

```bash
# Actualizar aplicación
git pull
docker-compose build
docker-compose up -d

# Ver logs
docker-compose logs -f

# Backup base de datos
docker exec postgres-container pg_dump -U user db > backup.sql

# Reiniciar servicios
docker-compose restart backend frontend
```

---

**¡Tu EcoMarket está listo para producción en AWS! 🚀**

*Última actualización: 4 de Diciembre, 2025*