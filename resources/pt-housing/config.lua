HousingConfig = HousingConfig or {}

-- Exemplos de propriedades (pode ser substituído por DB)
HousingConfig.Properties = HousingConfig.Properties or {
  { id = 'mp_mirror_01', label = 'Mirror Park 01', entrance = vector3(1026.8, -408.5, 65.95), mailbox = vector3(1029.0, -408.6, 65.95), price = 250000, tier = 2 },
  { id = 'mp_mirror_02', label = 'Mirror Park 02', entrance = vector3(999.3, -593.1, 59.5), mailbox = vector3(1001.4, -593.2, 59.5), price = 180000, tier = 1 },
}

-- Regras
HousingConfig.ListingFee = 1000           -- taxa fixa por listar para venda
HousingConfig.RentPeriodMinutes = 120     -- tempo de arrendamento por período
HousingConfig.MaxOwnedPerPlayer = 3       -- limite de propriedades por jogador
