# Base de Dados para QBCore (MariaDB)

Este setup usa Docker para levantar uma MariaDB compatível com o `server.cfg`.

Dados de ligação:
- Host: 127.0.0.1
- Porta: 3306 (mapeada do container)
- Database: qbcore
- User: qbcore
- Password: qbcore_pass
- Root Password: fivemrootpass

Como iniciar:
1. Instala Docker e Docker Compose.
2. Na pasta `server-data/db`, executa:
   - `docker compose up -d`
3. Espera ~5-10s e liga com HeidiSQL usando os dados acima.

Importar dados:
- Abre a DB `qbcore` no HeidiSQL e carrega o ficheiro `../sql/all_in_one_pt.sql`.

Parar/remover:
- `docker compose down`

Persistência:
- Os dados ficam no volume `db_data`.