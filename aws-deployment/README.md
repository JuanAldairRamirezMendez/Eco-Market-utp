# Configuración para deployment en AWS ECS

## 🚀 Pasos para desplegar EcoMarket en AWS

### 1. Prerequisitos
```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
```

### 2. Configurar variables
Edita `deploy.sh` y reemplaza:
- `YOUR_ACCOUNT_ID` - Tu ID de cuenta AWS
- `us-east-1` - Tu región preferida
- `subnet-12345,subnet-67890` - IDs de tus subnets
- `sg-abcdef` - ID de tu security group

### 3. Crear RDS PostgreSQL
```bash
aws rds create-db-instance \
    --db-instance-identifier ecomarket-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 14.9 \
    --allocated-storage 20 \
    --db-name ecomarket_db \
    --master-username ecomarket_user \
    --master-user-password "TU_PASSWORD_SEGURO" \
    --vpc-security-group-ids sg-abcdef \
    --db-subnet-group-name default \
    --backup-retention-period 7 \
    --storage-encrypted
```

### 4. Crear secrets en AWS Secrets Manager
```bash
# JWT Secret
aws secretsmanager create-secret \
    --name "ecomarket/jwt-secret" \
    --description "JWT secret for EcoMarket" \
    --secret-string "09QK6DHuATCn383txu1Z1B6ybjkpuA163FjgWTdu/4emOixDQgTqJXS20XoYofFaEyP1U+ak3p1BqXzc24kgmQ=="

# Database credentials
aws secretsmanager create-secret \
    --name "ecomarket/db-host" \
    --secret-string "ecomarket-db.cluster-abc123.us-east-1.rds.amazonaws.com"

aws secretsmanager create-secret \
    --name "ecomarket/db-username" \
    --secret-string "ecomarket_user"

aws secretsmanager create-secret \
    --name "ecomarket/db-password" \
    --secret-string "TU_PASSWORD_SEGURO"
```

### 5. Ejecutar deployment
```bash
chmod +x aws-deployment/deploy.sh
./aws-deployment/deploy.sh
```

### 6. Crear Application Load Balancer
```bash
# Crear ALB
aws elbv2 create-load-balancer \
    --name ecomarket-alb \
    --subnets subnet-12345 subnet-67890 \
    --security-groups sg-abcdef

# Crear target group
aws elbv2 create-target-group \
    --name ecomarket-targets \
    --protocol HTTP \
    --port 80 \
    --vpc-id vpc-12345 \
    --target-type ip \
    --health-check-path /health
```

## 🔧 Arquitectura AWS

```
Internet Gateway
       ↓
Application Load Balancer (ALB)
       ↓
ECS Fargate Service
├── Frontend Container (port 80)
└── Backend Container (port 8080)
       ↓
RDS PostgreSQL
       ↓
S3 Bucket (images)
```

## 💰 Costos estimados (mensual)
- ECS Fargate: ~$30-50
- RDS t3.micro: ~$15
- ALB: ~$20
- S3: ~$5
- **Total: ~$70-90/mes**

## 🔍 Monitoreo
- CloudWatch Logs: `/ecs/ecomarket`
- Health checks automáticos
- Auto-scaling disponible

## 🚨 Seguridad
- ✅ Secrets Manager para credenciales
- ✅ VPC con security groups
- ✅ HTTPS con ALB
- ✅ JWT tokens seguros