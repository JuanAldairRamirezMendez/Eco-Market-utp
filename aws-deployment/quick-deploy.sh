#!/bin/bash

# Script para desplegar EcoMarket en EC2 Ubuntu con Docker
# Para exposición universitaria - Configuración rápida

set -e

echo "🚀 Desplegando EcoMarket en AWS EC2 Ubuntu..."

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
INSTANCE_TYPE="t2.micro"  # Free tier
AMI_ID="ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS
KEY_NAME="ecomarket-key"
SECURITY_GROUP="ecomarket-sg"

echo -e "${YELLOW}1. Creando key pair para SSH...${NC}"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ecomarket-key.pem
chmod 400 ecomarket-key.pem
echo "✅ Key creada: ecomarket-key.pem"

echo -e "${YELLOW}2. Creando security group...${NC}"
SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP \
    --description "Security group para EcoMarket demo" \
    --query 'GroupId' --output text)

# Abrir puertos necesarios
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0    # SSH
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0    # HTTP
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 3000 --cidr 0.0.0.0/0  # Frontend
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0  # Backend

echo "✅ Security group creado: $SG_ID"

echo -e "${YELLOW}3. Lanzando instancia EC2 t2.micro (Free Tier)...${NC}"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EcoMarket-Demo}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "✅ Instancia lanzada: $INSTANCE_ID"

echo -e "${YELLOW}4. Esperando que la instancia esté running...${NC}"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "✅ Instancia corriendo en IP: $PUBLIC_IP"

echo -e "${YELLOW}5. Creando script de configuración...${NC}"
cat > setup-server.sh << 'EOF'
#!/bin/bash
set -e

echo "🐳 Instalando Docker..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose

echo "👤 Configurando usuario para Docker..."
sudo usermod -aG docker ubuntu
sudo systemctl start docker
sudo systemctl enable docker

echo "📥 Instalando git..."
sudo apt install -y git

echo "✅ Servidor configurado para Docker!"
EOF

echo -e "${YELLOW}6. Copiando archivos al servidor...${NC}"
# Esperar a que SSH esté disponible
sleep 60

# Copiar script de setup
scp -i ecomarket-key.pem -o StrictHostKeyChecking=no setup-server.sh ubuntu@$PUBLIC_IP:~/

# Ejecutar setup
ssh -i ecomarket-key.pem -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP 'chmod +x setup-server.sh && ./setup-server.sh'

echo -e "${GREEN}✅ EC2 configurado!${NC}"
echo ""
echo -e "${BLUE}🖥️  Para conectarte al servidor:${NC}"
echo -e "${BLUE}   ssh -i ecomarket-key.pem ubuntu@$PUBLIC_IP${NC}"
echo ""
echo -e "${BLUE}🚀 Comandos para desplegar en el servidor:${NC}"
cat << EOF

# 1. Conectarse al servidor
ssh -i ecomarket-key.pem ubuntu@$PUBLIC_IP

# 2. Clonar tu repositorio
git clone https://github.com/Felakz/EcoMarket-utp.git
cd EcoMarket-utp

# 3. Construir y ejecutar con Docker
sudo docker-compose up -d --build

# 4. Ver logs
sudo docker-compose logs -f

EOF

echo ""
echo -e "${GREEN}🌐 URLs de tu aplicación:${NC}"
echo -e "${GREEN}   Frontend: http://$PUBLIC_IP:3000${NC}"
echo -e "${GREEN}   Backend: http://$PUBLIC_IP:8080/ecomarket${NC}"
echo ""
echo -e "${YELLOW}💰 Costo: ~\$8/mes (t2.micro Free Tier: primeros 12 meses gratis)${NC}"
echo ""
echo -e "${BLUE}📝 Guarda estos datos:${NC}"
echo -e "${BLUE}   IP: $PUBLIC_IP${NC}"
echo -e "${BLUE}   Instance ID: $INSTANCE_ID${NC}"
echo -e "${BLUE}   Key file: ecomarket-key.pem${NC}"