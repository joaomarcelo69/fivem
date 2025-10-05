pt-vehicle-docs
================

Registo e verificação de documentos de veículos (seguro/inspeção), integração com STOP e apreensão com taxas.

Comandos do jogador
- /renovarseguro — renova o seguro do veículo onde está ou em frente (cobra via banco)
- /renovarinspecao — renova a inspeção do veículo onde está ou em frente (cobra via banco)
- /levantarapreensao [MATRICULA] — levanta a apreensão pagando a taxa calculada

Fluxo STOP (LEO)
1) No Job Menu (F6) → Operação STOP → “Verificar Docs” para ver validade de seguro/inspeção
2) “Apreender (sem docs)” chama validação; se inválidos, regista apreensão e remove o veículo do mundo

Configuração (`config.lua`)
- insuranceMonths, inspectionMonths — validade em meses
- baseFines — valores de multa para ausência de seguro/inspeção
- impound.baseFee, impound.perDay — taxa de levantamento de apreensão

Base de dados
- vehicle_docs(plate PK, owner, insurance_exp, inspection_exp)
- vehicle_impounds(plate PK, owner, seized_at, reason, by_officer)
