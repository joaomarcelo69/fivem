# 🇵🇹 Guia de Instalação - Servidor FiveM Português

## 📋 Pré-requisitos

### Windows
- **FXServer** - Download oficial
- **MariaDB/MySQL** - Base de dados
- **Node.js** - Para screenshot-basic
- **Git** (opcional) - Para updates

### Linux
- **FXServer** - Download oficial  
- **MariaDB/MySQL** - Base de dados
- **Node.js** - Para screenshot-basic
- **Git** (opcional) - Para updates

## 🚀 Instalação Passo-a-Passo

### 1. Download do FXServer

#### Windows:
```bash
# Vai a: https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/
# Baixa a versão mais recente (ex: 7290-e5ea9e6ea9c78de0de97ebbb25322061551a72f3)
# Extrai para: C:\fxserver\
```

#### Linux:
```bash
# Cria pasta
mkdir -p ~/fxserver
cd ~/fxserver

# Download (substitui XXXX pela build mais recente)
wget https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/XXXX-HASH/fx.tar.xz

# Extrai
tar -xf fx.tar.xz
```

### 2. Clona este Repositório

```bash
# Clone
git clone https://github.com/joaomarcelo69/fivem.git servidor-pt
cd servidor-pt

# Ou download ZIP de: https://github.com/joaomarcelo69/fivem
```

### 3. Setup Base de Dados

#### Instalar MariaDB/MySQL

**Windows:**
- Download: https://mariadb.org/download/
- Instala com root password: `fivemrootpass`

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install mariadb-server

# Configura
sudo mysql_secure_installation
# Define password root: fivemrootpass
```

#### Criar Base de Dados

```bash
# Entra no MySQL
mysql -u root -p

# Cria BD
CREATE DATABASE qbcore;
exit

# Importa schemas
mysql -u root -p qbcore < server-data/sql/qbcore_min_schema.sql
mysql -u root -p qbcore < server-data/sql/pt_schema.sql
```

### 4. Configura o Servidor

#### Copia FXServer para o projeto:
```bash
# Windows
xcopy C:\fxserver\* fxserver\ /E /I

# Linux  
cp -r ~/fxserver/* fxserver/
```

#### Ajusta configuração:

Edita `server-data/server.cfg`:

```properties
# Muda para a tua license key
set sv_licenseKey "A_TUA_CHAVE_AQUI"

# Ajusta BD se necessário (se usas porta diferente)
set mysql_connection_string "mysql://root:fivemrootpass@127.0.0.1:3306/qbcore"

# Nome do servidor
sv_hostname "O Teu Servidor RP PT"
```

### 5. Instala Dependências Node.js

```bash
# Entra na pasta screenshot-basic
cd fxserver/resources/screenshot-basic

# Instala dependências
npm install

# Compila
npm run build

# Volta à raiz
cd ../../../
```

### 6. Arranca o Servidor

#### Windows:
```cmd
cd fxserver
FXServer.exe +exec server.cfg
```

#### Linux:
```bash
cd fxserver
./run.sh +exec server.cfg
```

## 🎮 Como Conectar

### FiveM Client:
- **IP:** `127.0.0.1:30125` (local)
- **IP:** `SEU_IP_PUBLICO:30125` (remoto)

### Direct Connect:
1. Abre FiveM
2. Vai a "Play" → "Direct Connect"  
3. Escreve: `127.0.0.1:30125`

## 🛠️ Recursos Incluídos

### QBCore Base:
- ✅ qb-core, qb-inventory, qb-phone
- ✅ qb-weapons, qb-apartments

### Recursos Portugueses:
- ✅ **pt-shops** - Lojas portuguesas
- ✅ **pt-police** - Sistema polícia PT  
- ✅ **pt-jobs** - Empregos portugueses
- ✅ **pt-hospital** - Sistema hospitalar
- ✅ **pt-firefighters** - Bombeiros
- ✅ **pt-vehicle-docs** - Documentos veículos
- ✅ **pt-speedcams** - Radares velocidade
- ✅ **pt-tolls** - Portagens Via Verde
- ✅ **pt-multas** - Sistema multas
- ✅ **pt-placas** - Placas portuguesas
- ✅ **pt-commerce** - E-commerce + CTT
- ✅ **pt-housing** - Sistema habitação
- ✅ **pt-furniture** - Mobiliário
- ✅ **pt-dispatch** - Central despacho
- ✅ **pt-activities** - Atividades (mecânico, taxi)
- ✅ **pt-patrols** - Patrulhamento
- ✅ **pt-inspections** - Inspeções
- ✅ **pt-fisco** - Sistema fiscal

### Ferramentas:
- ✅ **screenshot-basic** - Capturas de ecrã
- ✅ **smoke_tests** - Testes automáticos
- ✅ **pt-health** - Monitor saúde BD

## 🔧 Configuração Avançada

### Portas:
- **Servidor:** 30125 (TCP/UDP)
- **txAdmin:** 40120 (HTTP)

### Base de Dados:
- **Host:** 127.0.0.1:3306
- **User:** root  
- **Pass:** fivemrootpass
- **BD:** qbcore

### Logs:
- **Servidor:** `fxserver/txData/FXServer.log`
- **Health:** `verification_report.txt`

## 🆘 Resolução Problemas

### "DB FALHOU":
1. Verifica se MySQL está ativo
2. Confirma credenciais em server.cfg
3. Importa schemas SQL

### "Resource não encontrado":
1. Verifica `server-data/server.cfg`
2. Confirma recursos em `fxserver/resources/`

### "Connection refused":
1. Verifica se servidor arrancou
2. Confirma portas abertas no firewall
3. Testa: `curl http://127.0.0.1:30125`

## 📞 Suporte

- **Logs:** Sempre partilha os logs do erro
- **Config:** Verifica server.cfg está correto
- **BD:** Confirma MySQL está ativo

## 🎉 Pronto!

O teu servidor português QBCore está pronto para funcionar!

**Funcionalidades:**
- 🏪 Lojas portuguesas
- 👮 Sistema policial PSP/GNR  
- 🚑 Hospital e bombeiros
- 🏠 Habitação e mobiliário
- 📱 Telefone com apps PT
- 🚗 Documentos e placas PT
- 💰 Sistema fiscal português
- 🛣️ Radares e portagens
- 📦 E-commerce com CTT

**Diverte-te!** 🇵🇹