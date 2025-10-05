#!/bin/bash

echo "===========================================" 
echo "🇵🇹 RP PORTUGAL - QBCORE SERVER STARTER 🇵🇹"
echo "==========================================="
echo ""

# Verificar se a base de dados está a correr
echo "🔍 Verificando base de dados..."
if ! docker ps | grep -q "qb-mariadb"; then
    echo "🔄 Iniciando MariaDB..."
    docker run -d \
      --name qb-mariadb \
      -e MYSQL_ROOT_PASSWORD=qbcore_pass \
      -e MYSQL_DATABASE=qbcore \
      -e MYSQL_USER=qbcore \
      -e MYSQL_PASSWORD=qbcore_pass \
      -e MYSQL_CHARSET=utf8mb4 \
      -e MYSQL_COLLATION=utf8mb4_unicode_ci \
      -p 127.0.0.1:3307:3306 \
      --restart unless-stopped \
      mariadb:10.11 \
      --default-authentication-plugin=mysql_native_password \
      --character-set-server=utf8mb4 \
      --collation-server=utf8mb4_unicode_ci \
      --max_connections=1000 \
      --innodb_buffer_pool_size=256M
    
    echo "⏳ Aguardando 15 segundos para inicialização..."
    sleep 15
fi

# Testar conexão à base de dados
echo "🔗 Testando conexão à base de dados..."
if mysql -h 127.0.0.1 -P 3307 -u qbcore -pqbcore_pass qbcore -e "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ Base de dados OK!"
else
    echo "❌ Erro na base de dados!"
    exit 1
fi

echo ""
echo "🚀 Iniciando FXServer..."
echo "📱 txAdmin: http://localhost:40120"
echo "🎮 Server: connect localhost:30125"
echo ""
echo "Para parar o servidor: Ctrl+C"
echo ""

# Iniciar o servidor
cd "$(dirname "$0")"
exec ./run.sh +set sv_licenseKey cfxk_2CoIidtbhW6hqrOmN2OZ_MIwa8 +set gamename gta5