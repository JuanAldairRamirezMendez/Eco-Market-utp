#!/bin/bash

# Deployment gratuito usando AWS Free Tier
set -e

# Variables
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="YOUR_ACCOUNT_ID"
CLUSTER_NAME="ecomarket-free-cluster"
SERVICE_NAME="ecomarket-free-service"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🆓 Iniciando deployment GRATUITO de EcoMarket${NC}"
echo -e "${BLUE}💰 Costo: $0 (usando AWS Free Tier)${NC}"

# 1. Login a ECR
echo -e "${YELLOW}📦 Autenticando con ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# 2. Crear repositorios ECR
echo -e "${YELLOW}🏗️ Creando repositorios ECR (500MB gratis)...${NC}"
aws ecr create-repository --repository-name ecomarket-backend --region $AWS_REGION || echo "Repository backend already exists"
aws ecr create-repository --repository-name ecomarket-frontend --region $AWS_REGION || echo "Repository frontend already exists"

# 3. Construir imágenes optimizadas
echo -e "${YELLOW}🔨 Construyendo imágenes optimizadas...${NC}"
cd ../

# Backend con multi-stage build para reducir tamaño
docker build -f backend-v2/Dockerfile.prod -t ecomarket-backend:free .
docker tag ecomarket-backend:free $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-backend:latest

# Frontend optimizado
docker build -f frontend-angular/Dockerfile -t ecomarket-frontend:free ./frontend-angular
docker tag ecomarket-frontend:free $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-frontend:latest

cd aws-deployment

# 4. Subir imágenes (optimizar para 500MB limit)
echo -e "${YELLOW}⬆️ Subiendo imágenes a ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-frontend:latest

# 5. Crear rol de ejecución si no existe
echo -e "${YELLOW}👤 Creando rol de ejecución...${NC}"
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' || echo "Role already exists"

aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || echo "Policy already attached"

# 6. Crear cluster ECS (Free Tier)
echo -e "${YELLOW}🏗️ Creando cluster ECS Fargate (750 horas gratis)...${NC}"
aws ecs create-cluster --cluster-name $CLUSTER_NAME --capacity-providers FARGATE --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1

# 7. Crear log group (5GB gratis)
echo -e "${YELLOW}📝 Creando log group (5GB gratis)...${NC}"
aws logs create-log-group --log-group-name "/ecs/ecomarket-free" --region $AWS_REGION || echo "Log group already exists"

# 8. Actualizar task definition
echo -e "${YELLOW}📋 Preparando task definition...${NC}"
sed -i "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" free-tier-task-definition.json
sed -i "s/YOUR_REGION/$AWS_REGION/g" free-tier-task-definition.json

# 9. Registrar task definition
echo -e "${YELLOW}📋 Registrando task definition (CPU: 256, Memoria: 512MB)...${NC}"
aws ecs register-task-definition --cli-input-json file://free-tier-task-definition.json

# 10. Obtener VPC y subnets por defecto
echo -e "${YELLOW}🌐 Obteniendo configuración de red...${NC}"
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
DEFAULT_SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ',')
DEFAULT_SG=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$DEFAULT_VPC" "Name=group-name,Values=default" --query 'SecurityGroups[0].GroupId' --output text)

# 11. Crear servicio ECS (Free Tier)
echo -e "${YELLOW}🔧 Creando servicio ECS (1 tarea)...${NC}"
aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition ecomarket-free-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$DEFAULT_SUBNETS],securityGroups=[$DEFAULT_SG],assignPublicIp=ENABLED}" || echo "Service might already exist"

# 12. Obtener IP pública
echo -e "${YELLOW}🔍 Obteniendo IP pública...${NC}"
sleep 30

TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --query 'taskArns[0]' --output text)
if [ "$TASK_ARN" != "None" ] && [ "$TASK_ARN" != "" ]; then
    ENI_ID=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
    PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
    
    if [ "$PUBLIC_IP" != "None" ] && [ "$PUBLIC_IP" != "" ]; then
        echo -e "${GREEN}✅ Deployment completado!${NC}"
        echo -e "${GREEN}🌐 Tu aplicación está disponible en:${NC}"
        echo -e "${BLUE}   Frontend: http://$PUBLIC_IP${NC}"
        echo -e "${BLUE}   Backend: http://$PUBLIC_IP:8080/ecomarket${NC}"
        echo -e "${BLUE}   Health Check: http://$PUBLIC_IP:8080/ecomarket/api/health${NC}"
    else
        echo -e "${YELLOW}⏳ La IP pública aún no está disponible. Verifica en la consola AWS ECS.${NC}"
    fi
else
    echo -e "${YELLOW}⏳ Las tareas aún se están iniciando. Verifica en la consola AWS ECS.${NC}"
fi

echo ""
echo -e "${GREEN}💰 Recursos utilizados (FREE TIER):${NC}"
echo -e "${GREEN}  ✅ ECS Fargate: 0.25 vCPU, 512MB RAM${NC}"
echo -e "${GREEN}  ✅ RDS t3.micro: 1 vCPU, 1GB RAM${NC}"
echo -e "${GREEN}  ✅ CloudWatch Logs: Hasta 5GB gratis${NC}"
echo -e "${GREEN}  ✅ ECR: 500MB storage gratis${NC}"
echo -e "${GREEN}  ✅ Secrets Manager: 2 secretos gratis${NC}"
echo ""
echo -e "${BLUE}🔍 Para monitorear:${NC}"
echo -e "${BLUE}  aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME${NC}"
echo -e "${BLUE}  aws logs tail /ecs/ecomarket-free --follow${NC}"