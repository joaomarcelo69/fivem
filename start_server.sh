#!/bin/bash

echo "🚀 Iniciando Servidor FiveM RP Portugal..."

# Verificar se MariaDB está a correr
if ! docker ps | grep -q qb-mariadb; then
    echo "📊 Iniciando MariaDB..."
    docker run -d --name qb-mariadb \
        -e MYSQL_ROOT_PASSWORD=qbcore_root_pass \
        -e MYSQL_DATABASE=qbcore \
        -e MYSQL_USER=qbcore \
        -e MYSQL_PASSWORD=qbcore_pass \
        -p 3307:3306 \
        mariadb:10.6 \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_unicode_ci \
        --default-authentication-plugin=mysql_native_password
    
    echo "⏳ Aguardando MariaDB inicializar..."
    sleep 15
fi

# Verificar conexão com base de dados
echo "🔍 Testando conexão com base de dados..."
if docker exec qb-mariadb mysql -uqbcore -pqbcore_pass -e "SELECT 1;" qbcore 2>/dev/null; then
    echo "✅ Base de dados conectada!"
else
    echo "❌ Erro na conexão com base de dados!"
    exit 1
fi

# Verificar se FXServer existe
if [ ! -f "fxserver/run.sh" ]; then
    echo "📥 Baixando FXServer..."
    cd fxserver
    curl -LO https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/fx.tar.xz
    tar -xf fx.tar.xz
    rm fx.tar.xz
    cd ..
fi

# Iniciar servidor
echo "🎮 Iniciando FXServer..."
cd fxserver
bash run.sh +exec ../server-data/server.cfg