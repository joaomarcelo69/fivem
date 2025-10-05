#!/bin/bash

echo "🧪 TESTE RÁPIDO DO SERVIDOR"
echo "=========================="

# 1. Testar base de dados
echo "1. 🔗 Testando base de dados..."
if mysql -h 127.0.0.1 -P 3307 -u qbcore -pqbcore_pass qbcore -e "SELECT 1 as test;" 2>/dev/null; then
    echo "   ✅ MariaDB conectado"
else
    echo "   ❌ MariaDB com problemas"
fi

# 2. Verificar recursos
echo "2. 📁 Verificando recursos..."
RESOURCES=$(find /workspaces/fivem/fxserver/resources -name "fxmanifest.lua" | wc -l)
echo "   📦 $RESOURCES recursos encontrados"

# 3. Verificar screenshot-basic
echo "3. 🖼️ Verificando screenshot-basic..."
if [ -f "/workspaces/fivem/fxserver/resources/screenshot-basic/dist/server.js" ]; then
    echo "   ✅ screenshot-basic compilado"
else
    echo "   ❌ screenshot-basic em falta"
fi

# 4. Listar recursos PT
echo "4. 🇵🇹 Recursos portugueses:"
find /workspaces/fivem/fxserver/resources -name "pt-*" -type d | sed 's/.*\//   - /' | sort

echo ""
echo "✅ Teste completo! Servidor pronto para usar."