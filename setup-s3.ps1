# =============================================================================
# EcoMarket - AWS S3 Setup Script (PowerShell)
# =============================================================================

param(
    [string]$BucketName = "ecomarket-products-$(Get-Date -Format 'yyyyMMddHHmmss')",
    [string]$Region = "us-east-1",
    [string]$Profile = "default",
    [switch]$Help
)

if ($Help) {
    Write-Host @"
EcoMarket AWS S3 Setup Script

USAGE:
    .\setup-s3.ps1 [-BucketName <name>] [-Region <region>] [-Profile <profile>]

EXAMPLES:
    .\setup-s3.ps1
    .\setup-s3.ps1 -BucketName "mi-ecomarket-bucket" -Region "us-west-2"
    .\setup-s3.ps1 -Profile "production"

PARAMETERS:
    -BucketName  : Nombre del bucket S3 (default: ecomarket-products-timestamp)
    -Region      : Región AWS (default: us-east-1)
    -Profile     : Perfil AWS CLI (default: default)
    -Help        : Muestra esta ayuda
"@
    exit 0
}

# Colores para output
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    switch ($Level) {
        "INFO" { Write-Host "[INFO] $Message" -ForegroundColor Green }
        "WARN" { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "TITLE" { Write-Host "$Message" -ForegroundColor Cyan }
    }
}

Write-Log "🚀 CONFIGURANDO AWS S3 PARA ECOMARKET" -Level "TITLE"
Write-Host "=================================================="
Write-Host "Bucket: $BucketName"
Write-Host "Región: $Region"
Write-Host "Profile: $Profile"
Write-Host ""

# =============================================================================
# 1. VERIFICAR AWS CLI
# =============================================================================

Write-Log "Verificando AWS CLI..."

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Log "AWS CLI no está instalado" -Level "ERROR"
    Write-Host "Descarga desde: https://aws.amazon.com/cli/"
    exit 1
}

# Verificar credenciales
try {
    $null = aws sts get-caller-identity --profile $Profile 2>$null
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Log "✅ AWS CLI configurado correctamente"
} catch {
    Write-Log "AWS credentials no configuradas correctamente" -Level "ERROR"
    Write-Host "Configura con: aws configure --profile $Profile"
    exit 1
}

# =============================================================================
# 2. CREAR BUCKET S3
# =============================================================================

Write-Log "Creando bucket S3: $BucketName"

# Verificar si el bucket ya existe
try {
    aws s3api head-bucket --bucket $BucketName --profile $Profile 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "El bucket $BucketName ya existe" -Level "WARN"
    }
} catch {
    # Crear bucket
    try {
        if ($Region -eq "us-east-1") {
            aws s3api create-bucket --bucket $BucketName --profile $Profile
        } else {
            aws s3api create-bucket --bucket $BucketName --region $Region --create-bucket-configuration LocationConstraint=$Region --profile $Profile
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ Bucket $BucketName creado exitosamente"
        } else {
            throw "Error creating bucket"
        }
    } catch {
        Write-Log "Error creando el bucket" -Level "ERROR"
        exit 1
    }
}

# =============================================================================
# 3. CONFIGURAR BUCKET POLICY
# =============================================================================

Write-Log "Configurando políticas del bucket..."

# Bloquear acceso público por defecto
try {
    aws s3api put-public-access-block --bucket $BucketName --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" --profile $Profile
    Write-Log "✅ Acceso público bloqueado"
} catch {
    Write-Log "Error configurando acceso público" -Level "WARN"
}

# Obtener Account ID
$AccountId = (aws sts get-caller-identity --query Account --output text --profile $Profile).Trim()

# Crear bucket policy
$BucketPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EcoMarketAppAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$AccountId:root"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::$BucketName/*"
        }
    ]
}
"@

$BucketPolicy | Out-File -FilePath "bucket-policy.json" -Encoding UTF8
aws s3api put-bucket-policy --bucket $BucketName --policy file://bucket-policy.json --profile $Profile

Write-Log "✅ Políticas de bucket configuradas"

# =============================================================================
# 4. CONFIGURAR CORS
# =============================================================================

Write-Log "Configurando CORS..."

$CorsConfig = @"
{
    "CORSRules": [
        {
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
            "AllowedOrigins": ["*"],
            "ExposeHeaders": ["ETag", "x-amz-request-id"]
        }
    ]
}
"@

$CorsConfig | Out-File -FilePath "cors-config.json" -Encoding UTF8
aws s3api put-bucket-cors --bucket $BucketName --cors-configuration file://cors-config.json --profile $Profile

Write-Log "✅ CORS configurado"

# =============================================================================
# 5. CREAR USUARIO IAM
# =============================================================================

Write-Log "Creando usuario IAM para EcoMarket..."

$IAMUser = "ecomarket-s3-user"
$PolicyName = "EcoMarketS3Policy"

# Crear usuario IAM si no existe
try {
    aws iam get-user --user-name $IAMUser --profile $Profile 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Usuario IAM $IAMUser ya existe" -Level "WARN"
    }
} catch {
    aws iam create-user --user-name $IAMUser --profile $Profile
    Write-Log "✅ Usuario IAM $IAMUser creado"
}

# Crear política IAM
$IAMPolicy = @"
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
                "arn:aws:s3:::$BucketName",
                "arn:aws:s3:::$BucketName/*"
            ]
        }
    ]
}
"@

$IAMPolicy | Out-File -FilePath "iam-policy.json" -Encoding UTF8
aws iam put-user-policy --user-name $IAMUser --policy-name $PolicyName --policy-document file://iam-policy.json --profile $Profile

Write-Log "✅ Política IAM configurada"

# =============================================================================
# 6. CREAR ACCESS KEYS
# =============================================================================

Write-Log "Creando Access Keys..."

# Eliminar keys existentes
$ExistingKeys = aws iam list-access-keys --user-name $IAMUser --profile $Profile --query 'AccessKeyMetadata[*].AccessKeyId' --output text
if ($ExistingKeys) {
    $ExistingKeys.Split() | ForEach-Object {
        if ($_.Trim()) {
            aws iam delete-access-key --user-name $IAMUser --access-key-id $_.Trim() --profile $Profile
        }
    }
}

# Crear nuevas access keys
$KeysOutput = aws iam create-access-key --user-name $IAMUser --profile $Profile --output json | ConvertFrom-Json
$AccessKeyId = $KeysOutput.AccessKey.AccessKeyId
$SecretAccessKey = $KeysOutput.AccessKey.SecretAccessKey

Write-Log "✅ Access Keys creadas"

# =============================================================================
# 7. SUBIR IMÁGENES EXISTENTES
# =============================================================================

Write-Log "Subiendo imágenes existentes a S3..."

$UploadDir = "backend-v2\uploads\products"
if (Test-Path $UploadDir) {
    aws s3 sync $UploadDir s3://$BucketName/products/ --profile $Profile --exclude "*" --include "*.jpg" --include "*.jpeg" --include "*.png" --include "*.gif" --include "*.webp"
    Write-Log "✅ Imágenes subidas a S3"
} else {
    Write-Log "Directorio de imágenes no encontrado: $UploadDir" -Level "WARN"
}

# =============================================================================
# 8. GENERAR ARCHIVO DE CONFIGURACIÓN
# =============================================================================

Write-Log "Generando configuración para aplicación..."

$ConfigContent = @"
# =============================================================================
# EcoMarket - AWS S3 Configuration
# Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# =============================================================================

# S3 Configuration
AWS_S3_ENABLED=true
AWS_S3_BUCKET=$BucketName
AWS_REGION=$Region
AWS_ACCESS_KEY_ID=$AccessKeyId
AWS_SECRET_ACCESS_KEY=$SecretAccessKey

# Para PowerShell (carga estas variables antes de docker-compose)
`$env:AWS_S3_ENABLED="true"
`$env:AWS_S3_BUCKET="$BucketName"
`$env:AWS_REGION="$Region"
`$env:AWS_ACCESS_KEY_ID="$AccessKeyId"
`$env:AWS_SECRET_ACCESS_KEY="$SecretAccessKey"

# Comandos para aplicar configuración
# . .\aws-s3-config.ps1
# docker-compose up -d
"@

$ConfigContent | Out-File -FilePath "aws-s3-config.ps1" -Encoding UTF8
Write-Log "✅ Configuración guardada en aws-s3-config.ps1"

# =============================================================================
# 9. LIMPIAR ARCHIVOS TEMPORALES
# =============================================================================

Remove-Item -Path "bucket-policy.json", "cors-config.json", "iam-policy.json" -ErrorAction SilentlyContinue

# =============================================================================
# 10. RESUMEN FINAL
# =============================================================================

Write-Host ""
Write-Log "🎉 CONFIGURACIÓN S3 COMPLETADA" -Level "TITLE"
Write-Host "=================================="
Write-Host ""
Write-Host "📍 Información del Bucket:" -ForegroundColor Blue
Write-Host "   Nombre: $BucketName"
Write-Host "   Región: $Region"
Write-Host "   URL: https://s3.$Region.amazonaws.com/$BucketName"
Write-Host ""
Write-Host "🔐 Credenciales (MANTENER SEGURAS):" -ForegroundColor Blue
Write-Host "   Access Key ID: $AccessKeyId"
Write-Host "   Secret Access Key: $SecretAccessKey"
Write-Host ""
Write-Host "⚡ Próximos pasos:" -ForegroundColor Blue
Write-Host "   1. . .\aws-s3-config.ps1"
Write-Host "   2. docker-compose up -d"
Write-Host "   3. Verificar que las imágenes se suban a S3"
Write-Host ""
Write-Host "🔗 URLs de ejemplo:" -ForegroundColor Blue
Write-Host "   https://s3.$Region.amazonaws.com/$BucketName/products/slide1.png"
Write-Host "   https://s3.$Region.amazonaws.com/$BucketName/products/slide2.jpg"
Write-Host ""
Write-Host "✅ ¡EcoMarket está listo para usar AWS S3!" -ForegroundColor Green