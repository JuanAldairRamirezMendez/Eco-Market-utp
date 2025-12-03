#!/bin/bash

# =============================================================================
# EcoMarket - AWS S3 Setup Script
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables por defecto
BUCKET_NAME=${1:-ecomarket-products-$(date +%s)}
REGION=${2:-us-east-1}
AWS_PROFILE=${3:-default}

echo -e "${BLUE}🚀 CONFIGURANDO AWS S3 PARA ECOMARKET${NC}"
echo "=================================================="
echo "Bucket: $BUCKET_NAME"
echo "Región: $REGION"
echo "Profile: $AWS_PROFILE"
echo ""

# Función de logging
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# =============================================================================
# 1. VERIFICAR AWS CLI
# =============================================================================

log "Verificando AWS CLI..."
if ! command -v aws &> /dev/null; then
    error "AWS CLI no está instalado"
    echo "Instala con: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Verificar credenciales
if ! aws sts get-caller-identity --profile $AWS_PROFILE &> /dev/null; then
    error "AWS credentials no configuradas correctamente"
    echo "Configura con: aws configure --profile $AWS_PROFILE"
    exit 1
fi

log "✅ AWS CLI configurado correctamente"

# =============================================================================
# 2. CREAR BUCKET S3
# =============================================================================

log "Creando bucket S3: $BUCKET_NAME"

# Verificar si el bucket ya existe
if aws s3api head-bucket --bucket $BUCKET_NAME --profile $AWS_PROFILE 2>/dev/null; then
    warn "El bucket $BUCKET_NAME ya existe"
else
    # Crear bucket
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket $BUCKET_NAME \
            --profile $AWS_PROFILE
    else
        aws s3api create-bucket \
            --bucket $BUCKET_NAME \
            --region $REGION \
            --create-bucket-configuration LocationConstraint=$REGION \
            --profile $AWS_PROFILE
    fi
    
    log "✅ Bucket $BUCKET_NAME creado exitosamente"
fi

# =============================================================================
# 3. CONFIGURAR BUCKET POLICY
# =============================================================================

log "Configurando políticas del bucket..."

# Bloquear acceso público por defecto
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --profile $AWS_PROFILE

# Crear bucket policy para la aplicación
cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EcoMarketAppAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text --profile $AWS_PROFILE):root"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy file:///tmp/bucket-policy.json \
    --profile $AWS_PROFILE

log "✅ Políticas de bucket configuradas"

# =============================================================================
# 4. CONFIGURAR CORS
# =============================================================================

log "Configurando CORS..."

cat > /tmp/cors-config.json << EOF
{
    "CORSRules": [
        {
            "AllowedHeaders": [
                "*"
            ],
            "AllowedMethods": [
                "GET",
                "PUT",
                "POST",
                "DELETE",
                "HEAD"
            ],
            "AllowedOrigins": [
                "*"
            ],
            "ExposeHeaders": [
                "ETag",
                "x-amz-request-id"
            ]
        }
    ]
}
EOF

aws s3api put-bucket-cors \
    --bucket $BUCKET_NAME \
    --cors-configuration file:///tmp/cors-config.json \
    --profile $AWS_PROFILE

log "✅ CORS configurado"

# =============================================================================
# 5. CREAR USUARIO IAM PARA LA APLICACIÓN
# =============================================================================

log "Creando usuario IAM para EcoMarket..."

IAM_USER="ecomarket-s3-user"
POLICY_NAME="EcoMarketS3Policy"

# Crear usuario IAM si no existe
if ! aws iam get-user --user-name $IAM_USER --profile $AWS_PROFILE &> /dev/null; then
    aws iam create-user \
        --user-name $IAM_USER \
        --profile $AWS_PROFILE
    
    log "✅ Usuario IAM $IAM_USER creado"
else
    warn "Usuario IAM $IAM_USER ya existe"
fi

# Crear política IAM
cat > /tmp/iam-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

# Crear/actualizar política
aws iam put-user-policy \
    --user-name $IAM_USER \
    --policy-name $POLICY_NAME \
    --policy-document file:///tmp/iam-policy.json \
    --profile $AWS_PROFILE

log "✅ Política IAM configurada"

# =============================================================================
# 6. CREAR ACCESS KEYS
# =============================================================================

log "Creando Access Keys..."

# Eliminar keys existentes si existen
aws iam list-access-keys --user-name $IAM_USER --profile $AWS_PROFILE \
    --query 'AccessKeyMetadata[*].AccessKeyId' --output text | \
    xargs -r -I {} aws iam delete-access-key --user-name $IAM_USER --access-key-id {} --profile $AWS_PROFILE

# Crear nuevas access keys
KEYS_OUTPUT=$(aws iam create-access-key \
    --user-name $IAM_USER \
    --profile $AWS_PROFILE \
    --output json)

ACCESS_KEY_ID=$(echo $KEYS_OUTPUT | jq -r '.AccessKey.AccessKeyId')
SECRET_ACCESS_KEY=$(echo $KEYS_OUTPUT | jq -r '.AccessKey.SecretAccessKey')

log "✅ Access Keys creadas"

# =============================================================================
# 7. SUBIR IMÁGENES EXISTENTES A S3
# =============================================================================

log "Subiendo imágenes existentes a S3..."

UPLOAD_DIR="../backend-v2/uploads/products"
if [ -d "$UPLOAD_DIR" ]; then
    # Subir todas las imágenes
    aws s3 sync $UPLOAD_DIR s3://$BUCKET_NAME/products/ \
        --profile $AWS_PROFILE \
        --exclude "*" \
        --include "*.jpg" \
        --include "*.jpeg" \
        --include "*.png" \
        --include "*.gif" \
        --include "*.webp"
    
    log "✅ Imágenes subidas a S3"
else
    warn "Directorio de imágenes no encontrado: $UPLOAD_DIR"
fi

# =============================================================================
# 8. GENERAR ARCHIVO DE CONFIGURACIÓN
# =============================================================================

log "Generando configuración para aplicación..."

cat > ../aws-s3-config.env << EOF
# =============================================================================
# EcoMarket - AWS S3 Configuration
# Generated on: $(date)
# =============================================================================

# S3 Configuration
AWS_S3_ENABLED=true
AWS_S3_BUCKET=$BUCKET_NAME
AWS_REGION=$REGION
AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY

# Para docker-compose.yml
export AWS_S3_ENABLED=true
export AWS_S3_BUCKET=$BUCKET_NAME
export AWS_REGION=$REGION
export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY

# Comando para aplicar configuración
# source aws-s3-config.env
# docker-compose up -d
EOF

log "✅ Configuración guardada en aws-s3-config.env"

# =============================================================================
# 9. LIMPIAR ARCHIVOS TEMPORALES
# =============================================================================

rm -f /tmp/bucket-policy.json /tmp/cors-config.json /tmp/iam-policy.json

# =============================================================================
# 10. RESUMEN FINAL
# =============================================================================

echo ""
echo -e "${GREEN}🎉 CONFIGURACIÓN S3 COMPLETADA${NC}"
echo "=================================="
echo ""
echo -e "${BLUE}📍 Información del Bucket:${NC}"
echo "   Nombre: $BUCKET_NAME"
echo "   Región: $REGION"
echo "   URL: https://s3.$REGION.amazonaws.com/$BUCKET_NAME"
echo ""
echo -e "${BLUE}🔐 Credenciales (MANTENER SEGURAS):${NC}"
echo "   Access Key ID: $ACCESS_KEY_ID"
echo "   Secret Access Key: $SECRET_ACCESS_KEY"
echo ""
echo -e "${BLUE}⚡ Próximos pasos:${NC}"
echo "   1. source aws-s3-config.env"
echo "   2. docker-compose up -d"
echo "   3. Verificar que las imágenes se suban a S3"
echo ""
echo -e "${BLUE}🔗 URLs de ejemplo:${NC}"
echo "   https://s3.$REGION.amazonaws.com/$BUCKET_NAME/products/slide1.png"
echo "   https://s3.$REGION.amazonaws.com/$BUCKET_NAME/products/slide2.jpg"
echo ""
echo -e "${GREEN}✅ ¡EcoMarket está listo para usar AWS S3!${NC}"