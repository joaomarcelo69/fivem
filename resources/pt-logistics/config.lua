LogiConfig = LogiConfig or {}

-- Pontos de importação (porto e aeroporto)
LogiConfig.ImportHubs = {
  { id='porto', label='Porto de Carga', coords=vector3(-278.48, -2656.57, 6.0) },
  { id='aeroporto', label='Aeroporto Carga', coords=vector3(-1035.42, -2737.64, 13.8) }
}

-- Armazém central
LogiConfig.Warehouse = { id='central', label='Armazém Central', coords=vector3(1061.9, -3109.5, -40.0) }

-- Capacidade por tipo de veículo (unidades)
LogiConfig.VehicleCapacity = {
  truck = 1000,   -- camião pesado
  van = 250       -- carrinha
}

-- Catálogo de mercadorias (SKU) -> itens de loja
-- Quantidades representam unidades de stock de loja.
LogiConfig.Products = {
  { sku='agua_palet', label='Palete de Água', yields = { { item='water', count=100 } } },
  { sku='pao_caixa', label='Caixa de Pão', yields = { { item='bread', count=100 } } },
  { sku='eletronica_mista', label='Lote Electrónica', yields = { { item='phone', count=10 }, { item='radio', count=20 } } }
}

-- Pontos de distribuição (lojas pt-shops alvo); se vazio, aceitar qualquer loja
LogiConfig.ShopWhitelist = {} -- e.g., { 'mercearia_lisboa', 'eletronica_lisboa' }

-- Limiares de stock por item (para NPCs decidirem quando reabastecer)
LogiConfig.MinStock = {
  water = 50,
  bread = 50,
  phone = 5,
  radio = 10
}

-- Durações de carregamento (em segundos)
LogiConfig.LoadingTimes = {
  import_truck = 30,   -- descarregar camião no armazém
  route_van = 15,      -- carregar carrinha no armazém
  route_truck = 30     -- carregar camião no armazém
}

-- NPCs automáticos: intervalo e critérios
LogiConfig.NPC = {
  enabled = true,
  checkIntervalSeconds = 120,      -- verificar a cada 2 min
  minLastDeliverySeconds = 1800     -- 30 min sem entrega => candidato
}
