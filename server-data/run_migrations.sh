#!/usr/bin/env bash
# Script simples para executar o SQL de schema se existir um MySQL com oxmysql configurado
set -euo pipefail

SQL_FILE="$(pwd)/sql/pt_schema.sql"
if [ ! -f "$SQL_FILE" ]; then
  echo "SQL file not found: $SQL_FILE"
  exit 1
fi

if [ -z "${MYSQL_CONN-}" ]; then
  echo "Exporte MYSQL_CONN com a connection string (ex: mysql://user:pass@127.0.0.1:3306/qbcore)"
  exit 1
fi

# Usar mysql client se disponível
if command -v mysql >/dev/null 2>&1; then
  # Extrair credenciais simples (não cubre todos os formatos)
  echo "Executando migrations usando mysql client..."
  # remover prefix
  conn=${MYSQL_CONN#mysql://}
  userpass=$(echo "$conn" | cut -d@ -f1)
  hostdb=$(echo "$conn" | cut -d@ -f2)
  user=$(echo "$userpass" | cut -d: -f1)
  pass=$(echo "$userpass" | cut -d: -f2)
  host=$(echo "$hostdb" | cut -d/ -f1)
  db=$(echo "$hostdb" | cut -d/ -f2)
  mysql -u"$user" -p"$pass" -h"$host" "$db" < "$SQL_FILE"
  echo "Migrations executadas."
else
  echo "Cliente mysql não encontrado. Rode manualmente: mysql -uuser -ppass -hhost db < $SQL_FILE"
  exit 1
fi
