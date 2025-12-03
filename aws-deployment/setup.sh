#!/bin/bash

# Script de configuración inicial para AWS
# Ejecutar una sola vez antes del deployment

set -e

echo "🚀 Configurando infraestructura AWS para EcoMarket..."

# Variables - ACTUALIZA ESTOS VALORES
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="YOUR_ACCOUNT_ID"
VPC_ID="vpc-12345"
SUBNET_1="subnet-12345"
SUBNET_2="subnet-67890"

echo "📋 Creando security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name ecomarket-sg \
    --description "Security group for EcoMarket application" \
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
    --db-subnet-group-name ecomarket-subnet-group \
    --db-subnet-group-description "Subnet group for EcoMarket RDS" \
    --subnet-ids $SUBNET_1 $SUBNET_2

echo "🗄️ Creando instancia RDS PostgreSQL..."
aws rds create-db-instance \
    --db-instance-identifier ecomarket-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 14.9 \
    --allocated-storage 20 \
    --db-name ecomarket_db \
    --master-username ecomarket_user \
    --master-user-password "EcoMarket2024!" \
    --vpc-security-group-ids $SECURITY_GROUP_ID \
    --db-subnet-group-name ecomarket-subnet-group \
    --backup-retention-period 7 \
    --storage-encrypted \
    --no-publicly-accessible

echo "⏳ Esperando a que RDS esté disponible..."
aws rds wait db-instance-available --db-instance-identifier ecomarket-db

# Obtener endpoint de RDS
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier ecomarket-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "RDS Endpoint: $RDS_ENDPOINT"

echo "🔐 Creando secrets en Secrets Manager..."

# JWT Secret
aws secretsmanager create-secret \
    --name "ecomarket/jwt-secret" \
    --description "JWT secret for EcoMarket" \
    --secret-string "$(openssl rand -base64 64)" || echo "Secret ya existe"

# Database host
aws secretsmanager create-secret \
    --name "ecomarket/db-host" \
    --secret-string "$RDS_ENDPOINT" || \
aws secretsmanager update-secret \
    --secret-id "ecomarket/db-host" \
    --secret-string "$RDS_ENDPOINT"

# Database username
aws secretsmanager create-secret \
    --name "ecomarket/db-username" \
    --secret-string "ecomarket_user" || echo "Secret ya existe"

# Database password
aws secretsmanager create-secret \
    --name "ecomarket/db-password" \
    --secret-string "EcoMarket2024!" || echo "Secret ya existe"

# AWS Access Key
echo "Por favor, proporciona tu AWS Access Key ID:"
read -r AWS_ACCESS_KEY
aws secretsmanager create-secret \
    --name "ecomarket/aws-access-key" \
    --secret-string "$AWS_ACCESS_KEY" || echo "Secret ya existe"

# AWS Secret Key
echo "Por favor, proporciona tu AWS Secret Access Key:"
read -rs AWS_SECRET_KEY
aws secretsmanager create-secret \
    --name "ecomarket/aws-secret-key" \
    --secret-string "$AWS_SECRET_KEY" || echo "Secret ya existe"

echo "🔧 Creando Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name ecomarket-alb \
    --subnets $SUBNET_1 $SUBNET_2 \
    --security-groups $SECURITY_GROUP_ID \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

echo "ALB ARN: $ALB_ARN"

echo "📊 Creando target group..."
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name ecomarket-targets \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-enabled \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "Target Group ARN: $TARGET_GROUP_ARN"

echo "🔗 Creando listener para ALB..."
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN

# Obtener DNS del ALB
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

echo "📝 Actualizando archivos de configuración..."

# Actualizar deploy.sh
sed -i "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" deploy.sh
sed -i "s/us-east-1/$AWS_REGION/g" deploy.sh
sed -i "s/subnet-12345,subnet-67890/$SUBNET_1,$SUBNET_2/g" deploy.sh
sed -i "s/sg-abcdef/$SECURITY_GROUP_ID/g" deploy.sh

# Actualizar task-definition.json
sed -i "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" task-definition.json
sed -i "s/us-east-1/$AWS_REGION/g" task-definition.json

echo "✅ Configuración completada!"
echo ""
echo "🌐 URLs importantes:"
echo "  - Application URL: http://$ALB_DNS"
echo "  - RDS Endpoint: $RDS_ENDPOINT"
echo "  - Security Group: $SECURITY_GROUP_ID"
echo ""
echo "🚀 Ahora puedes ejecutar: ./deploy.sh"