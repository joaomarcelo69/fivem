#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Starting MariaDB on port 3306 (user: qbcore / pass: qbcore_pass, db: qbcore)"
docker compose up -d
echo "Waiting for DB to be ready..."
sleep 5
echo "Containers:" 
docker compose ps
echo "Tip: connect via HeidiSQL -> Host: 127.0.0.1, Port: 3306, User: qbcore, Pass: qbcore_pass, DB: qbcore"
