# pt-valuetransport

Transporte de valores realista para RP Portugal QBCore

## Funcionalidades
- Missões de transporte de dinheiro entre bancos, ATMs, lojas, clientes
- Carrinha blindada (stockade) com NPCs seguranças armados
- Sistema de assaltos: minigame hacking/cofre, alertas polícias, logs
- Contratos VIP, rotas dinâmicas, reputação de empresa/jogador
- Economia dinâmica: ATMs/bancos/lojas dependem dos transportes
- Logs completos, painel admin, despachos automáticos
- UI/NUI para missões, contratos, histórico
- Integração total com jobs, phone, polícias

## Como usar
1. Dá job `valuetransport` ao jogador
2. Usa comando/evento para iniciar missão ou contrato VIP
3. Recolhe valores, entrega no destino, defende contra assaltos
4. Recebe dinheiro, reputação, logs

## Base de dados
- Tabela `value_transports`: missões
- Tabela `value_assaults`: assaltos
- Tabela `value_contracts`: contratos VIP
- Tabela `value_reputation`: reputação

## Expansão
- NUI avançada para painel de missões/admin
- Minigames de assalto/defesa
- Integração total com economia e phone
- Logs e despachos para admins
