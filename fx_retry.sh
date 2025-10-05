#!/usr/bin/env bash
set -euo pipefail
LOG=/workspaces/fivem/fx_start_retry.log
MAX=5
BACKOFF=5
cd /workspaces/fivem/fxserver

# Ensure MariaDB container is running before starting FXServer
if ! docker ps --format '{{.Names}}' | grep -q '^mariadb-fivem$'; then
  echo "Starting MariaDB container (mariadb-fivem) before FXServer..." | tee -a "$LOG"
  docker start mariadb-fivem >/dev/null 2>&1 || true
  # brief wait to allow DB to accept connections
  sleep 2
fi

# Kill any running server processes
pkill -f './run.sh' || true
sleep 1

> "$LOG"
for i in $(seq 1 $MAX); do
  echo "\n===== Attempt $i =====" | tee -a "$LOG"
  # ensure port 30125 free
  PIDS=$(ss -ltnp | grep ':30125' | sed -n 's/.*pid=\([0-9]*\),.*/\1/p' | sort -u || true)
  if [ -n "$PIDS" ]; then
    echo "Killing PIDs on 30120: $PIDS" | tee -a "$LOG"
    for p in $PIDS; do kill -9 $p || true; done
    sleep 1
  fi

  # start server
  nohup ./run.sh +exec ../server.cfg > "$LOG" 2>&1 &
  SERVER_PID=$!
  echo "Started run.sh (pid $SERVER_PID), waiting for auth..." | tee -a "$LOG"
  sleep 12

  # check logs for success or 429
  tail -n 300 "$LOG" > /tmp/fx_tail.txt || true
  if grep -q "Server license key authentication succeeded" /tmp/fx_tail.txt; then
    echo "License authenticated successfully on attempt $i" | tee -a "$LOG"
    break
  fi
  if grep -q "HTTP 429" /tmp/fx_tail.txt || grep -q "429 Too" /tmp/fx_tail.txt; then
    echo "Detected 429 rate limit on attempt $i" | tee -a "$LOG"
    kill -9 $SERVER_PID || true
    wait $SERVER_PID 2>/dev/null || true
    SLEEP=$((BACKOFF * (2 ** (i-1))))
    echo "Backing off for $SLEEP seconds..." | tee -a "$LOG"
    sleep $SLEEP
    continue
  fi
  # other fatal errors: check for bind error
  if grep -q "Could not bind on" /tmp/fx_tail.txt; then
    echo "Port bind error detected; aborting retries." | tee -a "$LOG"
    kill -9 $SERVER_PID || true
    break
  fi

  # if none matched, wait a bit and check again once
  sleep 8
  tail -n 300 "$LOG" > /tmp/fx_tail.txt || true
  if grep -q "Server license key authentication succeeded" /tmp/fx_tail.txt; then
    echo "License authenticated successfully on attempt $i (delayed)" | tee -a "$LOG"
    break
  fi
  echo "No authentication success, killing and retrying..." | tee -a "$LOG"
  kill -9 $SERVER_PID || true
  wait $SERVER_PID 2>/dev/null || true
  SLEEP=$((BACKOFF * (2 ** (i-1))))
  echo "Backing off for $SLEEP seconds..." | tee -a "$LOG"
  sleep $SLEEP
done

# show last 300 lines of log
echo "\n--- Final log tail ---" | tee -a "$LOG"
tail -n 300 "$LOG" | tee -a "$LOG"

# If license authenticated, run quick DB smoke test
if tail -n 300 "$LOG" | grep -q "Server license key authentication succeeded"; then
  echo "\nLicense OK — running smoke DB check..." | tee -a "$LOG"
  if docker ps --format '{{.Names}}' | grep -q '^mariadb-fivem$'; then
    docker exec mariadb-fivem mysql -uroot -pfivemrootpass -e "USE qbcore; SHOW TABLES;" | tee -a "$LOG"
  else
    echo "MariaDB container not running; skipping DB check." | tee -a "$LOG"
  fi
fi
