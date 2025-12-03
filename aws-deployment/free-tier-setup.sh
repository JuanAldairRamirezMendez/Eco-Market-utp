#!/bin/bash

# Deployment gratuito de EcoMarket usando AWS Free Tier
set -e

# Variables - ACTUALIZA ESTOS VALORES
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="YOUR_ACCOUNT_ID"
VPC_ID="vpc-12345"
SUBNET_1="subnet-12345"
SUBNET_2="subnet-67890"

echo "🆓 Configurando EcoMarket para AWS Free Tier..."

echo "📋 Creando security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name ecomarket-free-sg \
    --description "Security group for EcoMarket Free Tier" \
    --vpc-id $VPC_ID \
    --output text --query 'GroupId')

echo "Security Group ID: $SECURITY_GROUP_ID"

echo "🔒 Configurando reglas de security group..."
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $SECURITY_GROUP_ID

echo "📊 Creando subnet group para RDS..."
aws rds create-db-subnet-group \
    --db-subnet-group-name ecomarket-free-subnet-group \
    --db-subnet-group-description "Subnet group for EcoMarket Free RDS" \
    --subnet-ids $SUBNET_1 $SUBNET_2

echo "🆓 Creando RDS PostgreSQL en Free Tier..."
aws rds create-db-instance \
    --db-instance-identifier ecomarket-free-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 14.9 \
    --allocated-storage 20 \
    --max-allocated-storage 20 \
    --db-name ecomarket_db \
    --master-username ecomarket_user \
    --master-user-password "EcoMarket2024!" \
    --vpc-security-group-ids $SECURITY_GROUP_ID \
    --db-subnet-group-name ecomarket-free-subnet-group \
    --backup-retention-period 0 \
    --no-multi-az \
    --no-storage-encrypted \
    --no-publicly-accessible \
    --no-deletion-protection

echo "⏳ Esperando a que RDS esté disponible..."
aws rds wait db-instance-available --db-instance-identifier ecomarket-free-db

# Obtener endpoint de RDS
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier ecomarket-free-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "RDS Endpoint: $RDS_ENDPOINT"

echo "🔐 Creando secrets en Secrets Manager (2 gratis por mes)..."

# JWT Secret
aws secretsmanager create-secret \
    --name "ecomarket/jwt-secret" \
    --description "JWT secret for EcoMarket" \
    --secret-string "$(openssl rand -base64 64)" || echo "Secret ya existe"

# Database URL completa para Spring Boot
DB_URL="jdbc:postgresql://$RDS_ENDPOINT:5432/ecomarket_db"
aws secretsmanager create-secret \
    --name "ecomarket/database-config" \
    --secret-string "{\"url\":\"$DB_URL\",\"username\":\"ecomarket_user\",\"password\":\"EcoMarket2024!\"}" || \
aws secretsmanager update-secret \
    --secret-id "ecomarket/database-config" \
    --secret-string "{\"url\":\"$DB_URL\",\"username\":\"ecomarket_user\",\"password\":\"EcoMarket2024!\"}"

echo "📝 Actualizando archivos de configuración para Free Tier..."

# Crear configuración específica para Free Tier
cat > free-tier-task-definition.json << EOF
{
  "family": "ecomarket-free-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "ecomarket-backend",
      "image": "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-backend:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "SPRING_PROFILES_ACTIVE",
          "value": "production"
        },
        {
          "name": "AWS_REGION",
          "value": "$AWS_REGION"
        },
        {
          "name": "AWS_S3_BUCKET",
          "value": "ecomarket-images-prod"
        },
        {
          "name": "JWT_EXPIRATION",
          "value": "86400000"
        }
      ],
      "secrets": [
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:ecomarket/jwt-secret:SecretString::"
        },
        {
          "name": "DB_CONFIG",
          "valueFrom": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:ecomarket/database-config:SecretString::"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/ecomarket-free",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "backend"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "wget --no-verbose --tries=1 --spider http://localhost:8080/ecomarket/api/health || exit 1"
        ],
        "interval": 60,
        "timeout": 10,
        "retries": 3,
        "startPeriod": 120
      }
    },
    {
      "name": "ecomarket-frontend",
      "image": "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-frontend:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/ecomarket-free",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "frontend"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "wget --no-verbose --tries=1 --spider http://localhost:80 || exit 1"
        ],
        "interval": 60,
        "timeout": 10,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
EOF

echo "✅ Configuración Free Tier completada!"
echo ""
echo "🆓 Servicios configurados en Free Tier:"
echo "  - ECS Fargate: 750 horas/mes gratis"
echo "  - RDS t3.micro: 750 horas/mes gratis"
echo "  - Secrets Manager: 2 secretos gratis/mes"
echo "  - CloudWatch Logs: 5GB gratis/mes"
echo "  - ECR: 500MB storage gratis/mes"
echo ""
echo "💰 Costo mensual estimado: $0 (dentro de Free Tier)"
echo ""
echo "🚀 Ahora ejecuta: ./free-tier-deploy.sh"