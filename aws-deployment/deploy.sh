#!/bin/bash

# Script de deployment para AWS ECS
# Reemplaza las variables con tus valores reales

# Variables de configuración
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="YOUR_ACCOUNT_ID"
CLUSTER_NAME="ecomarket-cluster"
SERVICE_NAME="ecomarket-service"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Iniciando deployment de EcoMarket a AWS ECS${NC}"

# 1. Login a ECR
echo -e "${YELLOW}📦 Autenticando con ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# 2. Crear repositorios ECR si no existen
echo -e "${YELLOW}🏗️ Creando repositorios ECR...${NC}"
aws ecr create-repository --repository-name ecomarket-backend --region $AWS_REGION || echo "Repository backend already exists"
aws ecr create-repository --repository-name ecomarket-frontend --region $AWS_REGION || echo "Repository frontend already exists"

# 3. Tag y push de imágenes
echo -e "${YELLOW}🏷️ Taggeando imágenes...${NC}"
docker tag ecomarket-springboot-backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-backend:latest
docker tag ecomarket-springboot-frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-frontend:latest

echo -e "${YELLOW}⬆️ Subiendo imágenes a ECR...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ecomarket-frontend:latest

# 4. Crear cluster ECS si no existe
echo -e "${YELLOW}🏗️ Creando cluster ECS...${NC}"
aws ecs create-cluster --cluster-name $CLUSTER_NAME --capacity-providers FARGATE --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1

# 5. Crear log group
echo -e "${YELLOW}📝 Creando log group...${NC}"
aws logs create-log-group --log-group-name "/ecs/ecomarket" --region $AWS_REGION || echo "Log group already exists"

# 6. Registrar task definition
echo -e "${YELLOW}📋 Registrando task definition...${NC}"
# Reemplazar placeholders en task-definition.json
sed -i "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" aws-deployment/task-definition.json
sed -i "s/YOUR_REGION/$AWS_REGION/g" aws-deployment/task-definition.json

aws ecs register-task-definition --cli-input-json file://aws-deployment/task-definition.json

# 7. Crear servicio ECS
echo -e "${YELLOW}🔧 Creando servicio ECS...${NC}"
aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition ecomarket-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-12345,subnet-67890],securityGroups=[sg-abcdef],assignPublicIp=ENABLED}"

echo -e "${GREEN}✅ Deployment completado!${NC}"
echo -e "${GREEN}🌐 Tu aplicación estará disponible en el Load Balancer DNS${NC}"