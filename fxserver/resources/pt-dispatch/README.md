# pt-dispatch

Despacho simples para aumentar a atividade RP: cidadãos pedem assistência e serviços e as equipas aceitam e recebem rota no GPS.

Comandos (cidadão):
- /112 — Pedido às forças de segurança (PSP/GNR/PJ)
- /mec — Pedido aos mecânicos
- /taxi — Pedido a taxistas
- /reboque — Pedido de reboque

Comandos (equipa):
- Aceitar pedido: através do popup, ou /aceitar [id]
- Fechar pedido: /fecharcall [id]

Notas:
- O sistema deteta jobs police/psp/gnr/pj para o canal 112.
- Waypoint e blip são criados ao aceitar.

Config: `config.lua` para alterar nomes, cores e blips.
