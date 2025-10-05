# pt-valuetransport

Transporte de valores realista para RP Portugal QBCore

## Funcionalidades
- Missões de transporte de dinheiro entre bancos, ATMs, clientes
- Carrinha blindada (stockade)
- Integração com jobs: empresa de valores, polícias podem escoltar
- Alertas automáticos para polícias
- Registo de missões na base de dados
- Pronto para expansão: assaltos, minigames, NUI

## Como usar
1. Dá job `valuetransport` ao jogador
2. Usa comando/evento para iniciar missão
3. Recolhe valores, entrega no destino
4. Recebe dinheiro na conta bancária

## Base de dados
Tabela `value_transports`:
- id, pickup, dropoff, value, status, started_by

## Expansão
- Adicionar NUI para UI avançada
- Minigames de assalto/defesa
- Logs e despachos para admins
