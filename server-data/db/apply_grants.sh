#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
cat init/01-init-grants.sql | docker exec -i qb-mariadb mysql -uroot -pfivemrootpass
echo "Grants applied."
