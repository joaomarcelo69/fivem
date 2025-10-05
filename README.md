# 🇵🇹 RP Portugal - QBCore Server

**Servidor FiveM completamente em português com QBCore, recursos personalizados PT e funcionalidades avançadas.**

## 🚀 **Início Rápido**

### **1. Baixar o Servidor**
```bash
git clone https://github.com/joaomarcelo69/fivem.git
cd fivem
```

### **2. Instalar (Automático)**

**Linux:**
```bash
./setup_auto.sh
```

**Windows:**
```bash
setup_windows.bat
```

**Manual:** Seguir `SETUP_GUIDE.md`

### **3. Iniciar o Servidor**
```bash
cd fxserver
./start_server.sh
```

### **4. Conectar**
- **txAdmin:** http://localhost:40120
- **Jogo:** `connect localhost:30125`

## 📦 **O que está incluído**

### **Core**
- ✅ **QBCore** - Framework base
- ✅ **oxmysql** - Base de dados MySQL
- ✅ **MariaDB** - Container automático

### **Recursos Portugueses (37 total)**
- 🇵🇹 **pt-shops** - Lojas portuguesas
- 🚓 **pt-police** - Polícia PSP/GNR
- 🚑 **pt-hospital** - Hospital português  
- 👷 **pt-jobs** - Empregos PT
- 🏪 **pt-commerce** - E-commerce + CTT
- 🏠 **pt-housing** - Habitação + mobília
- 📱 **pt-phone** - Telemóvel PT
- 🚨 **pt-speedcams** - Radares PT
- 💰 **pt-tolls** - Via Verde
- 🚒 **pt-firefighters** - Bombeiros
- 📋 **pt-vehicle-docs** - Documentos veículos
- 🎯 **pt-activities** - Atividades
- 📡 **pt-dispatch** - Central 112
- 👮 **pt-patrols** - Patrulhas
- 🔍 **pt-inspections** - Inspeções
- E muito mais...

### **Funcionalidades Especiais**
- 📸 **Screenshot System** - Captura de imagens
- 🧪 **Smoke Tests** - Testes automáticos
- 💊 **Health Monitoring** - Monitorização
- 🎮 **QoL Features** - Qualidade de vida

## 🎮 **Como Jogar**

1. **Instalar FiveM:** https://fivem.net/
2. **Conectar:** F8 → `connect localhost:30125`
3. **Criar personagem** no QBCore
4. **Explorar** os recursos portugueses!

## 🔧 **Administração**

### **txAdmin**
- URL: http://localhost:40120
- Gestão completa do servidor
- Logs e monitorização

### **Comandos úteis**
```bash
# Testar servidor
./test_server.sh

# Ver logs
tail -f fxserver/run.log

# Reiniciar MariaDB
docker restart qb-mariadb
```

## �️ Base de Dados (rápido)

1. Inicia a MariaDB com Docker:
	- cd server-data/db
	- docker compose up -d
2. Liga com HeidiSQL: 127.0.0.1:3306 (user qbcore / pass qbcore_pass / db qbcore)
3. Importa: server-data/sql/all_in_one_pt.sql

## �📁 **Estrutura**

```
fivem/
├── fxserver/           # FXServer + recursos
├── server-data/        # Configurações
├── resources/          # Recursos adicionais  
├── SETUP_GUIDE.md      # Guia completo
├── setup_auto.sh       # Instalação Linux
└── setup_windows.bat   # Instalação Windows
```

## 🛠️ **Requisitos**

- **FXServer** (incluído nos scripts)
- **Docker** (MariaDB)
- **Node.js 18+** (screenshot-basic)
- **Linux/Windows** 

## 💡 **Suporte**

- 📖 **Guia completo:** `SETUP_GUIDE.md`
- 🔧 **Problemas:** Verificar logs em `fxserver/run.log`
- 🧪 **Testes:** `./test_server.sh`

---

**🎯 100% Português | 🎮 Pronto para Jogar | 🚀 Fácil de Usar**
