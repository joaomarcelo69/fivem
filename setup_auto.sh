#!/bin/bash
# Download e Setup Automático FXServer - Português
# Para Ubuntu/Debian Linux

set -e

echo "🇵🇹 Setup Automático - Servidor FiveM Português"
echo "================================================"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para logs coloridos
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verifica se é root
if [[ $EUID -eq 0 ]]; then
   log_error "Não executes como root!"
   exit 1
fi

# 1. Atualizar sistema
log_info "Atualizando sistema..."
sudo apt update

# 2. Instalar dependências
log_info "Instalando dependências..."
sudo apt install -y wget curl git mariadb-server nodejs npm

# 3. Configurar MariaDB
log_info "Configurando MariaDB..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Criar BD e utilizador
sudo mysql -e "CREATE DATABASE IF NOT EXISTS qbcore;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'fivem'@'localhost' IDENTIFIED BY 'fivempass';"
sudo mysql -e "GRANT ALL PRIVILEGES ON qbcore.* TO 'fivem'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# 4. Download FXServer (Linux)
log_info "Baixando FXServer..."
cd ~
mkdir -p fxserver_temp
cd fxserver_temp

# Obter última build
latest=$(curl -s "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/" | grep -oP 'href="\K[^"]*(?=/)' | tail -1)
log_info "Baixando build: $latest"

wget -q "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/$latest/fx.tar.xz"
tar -xf fx.tar.xz

# 5. Setup projeto
log_info "Configurando projeto..."
cd ~

# Clone repo se não existe
if [ ! -d "servidor-pt" ]; then
    git clone https://github.com/joaomarcelo69/fivem.git servidor-pt
fi

cd servidor-pt

# Copia FXServer
cp -r ~/fxserver_temp/* fxserver/
chmod +x fxserver/run.sh

# 6. Importar schemas BD
log_info "Importando schemas BD..."
mysql -u fivem -pfivempass qbcore < server-data/sql/qbcore_min_schema.sql
mysql -u fivem -pfivempass qbcore < server-data/sql/pt_schema.sql

# 7. Configurar server.cfg
log_info "Configurando servidor..."
cp server-data/server.cfg server-data/server.cfg.bak

# Ajusta string BD
sed -i 's/mysql:\/\/root:fivemrootpass@127.0.0.1:3307\/qbcore/mysql:\/\/fivem:fivempass@127.0.0.1:3306\/qbcore/' server-data/server.cfg

# 8. Instalar deps Node.js
log_info "Instalando dependências Node.js..."
cd fxserver/resources/screenshot-basic
npm install --silent
npm run build

cd ~/servidor-pt

# 9. Criar script de arranque
log_info "Criando script de arranque..."
cat > start_server.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "🇵🇹 Iniciando Servidor FiveM Português..."
echo "Acede: 127.0.0.1:30125"
echo "txAdmin: http://127.0.0.1:40120"
echo ""
cd fxserver
./run.sh +exec server.cfg
EOF

chmod +x start_server.sh

# 10. Limpeza
log_info "Limpando ficheiros temporários..."
rm -rf ~/fxserver_temp

# 11. Instruções finais
echo ""
echo "🎉 Setup Completo!"
echo "================="
echo ""
log_info "Para iniciar o servidor:"
echo "  cd ~/servidor-pt"
echo "  ./start_server.sh"
echo ""
log_info "Depois conecta no FiveM:"
echo "  IP: 127.0.0.1:30125"
echo ""
log_info "Configuração final necessária:"
echo "  1. Edita server-data/server.cfg"
echo "  2. Adiciona a tua license key FiveM"
echo "  3. Muda sv_hostname para o nome do teu servidor"
echo ""
log_warn "IMPORTANTE: Adiciona a tua license key em server-data/server.cfg!"
echo ""