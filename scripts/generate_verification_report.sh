#!/usr/bin/env bash
# Gera um relatório de verificação rápido para as tabelas chave do qbcore
OUTFILE="/workspaces/fivem/verification_report.txt"
DB_HOST=127.0.0.1
DB_PORT=3307
DB_USER=root
DB_PASS=fivemrootpass
DB_NAME=qbcore

set -euo pipefail

echo "Verification report generated: $(date -u)" > "$OUTFILE"

echo "\n-- Table counts --" >> "$OUTFILE"
mysql -u${DB_USER} -p${DB_PASS} -h${DB_HOST} -P${DB_PORT} ${DB_NAME} -e "SELECT 'players' as tbl, COUNT(*) as cnt FROM players; SELECT 'inventories', COUNT(*) FROM inventories; SELECT 'items', COUNT(*) FROM items; SELECT 'inventory_items', COUNT(*) FROM inventory_items; SELECT 'vehicle_plates', COUNT(*) FROM vehicle_plates; SELECT 'vehicles', COUNT(*) FROM vehicles; SELECT 'citizens', COUNT(*) FROM citizens; SELECT 'fines', COUNT(*) FROM fines;" >> "$OUTFILE"

echo "\n-- Recent vehicle_plates (last 20) --" >> "$OUTFILE"
mysql -u${DB_USER} -p${DB_PASS} -h${DB_HOST} -P${DB_PORT} ${DB_NAME} -e "SELECT id, plate, created_at FROM vehicle_plates ORDER BY id DESC LIMIT 20;" >> "$OUTFILE"

echo "\n-- Recent vehicles (last 20) --" >> "$OUTFILE"
mysql -u${DB_USER} -p${DB_PASS} -h${DB_HOST} -P${DB_PORT} ${DB_NAME} -e "SELECT id, plate, owner_citizenid, model FROM vehicles ORDER BY id DESC LIMIT 20;" >> "$OUTFILE"

echo "\n-- End of report --" >> "$OUTFILE"

chmod 644 "$OUTFILE"

echo "Report written to $OUTFILE"
