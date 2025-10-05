CommerceConfig = CommerceConfig or {}

CommerceConfig.Warehouse = CommerceConfig.Warehouse or {
  coords = vector3(120.6, -3022.3, 7.0),
  label = 'Armazém CTT',
}

-- Catálogo simplificado; podes expandir à vontade
CommerceConfig.Catalog = CommerceConfig.Catalog or {
  { id = 'food_box', label = 'Caixa de Comida', category = 'food', price = 250, contents = { { item = 'sandwich', count = 5 }, { item = 'water_bottle', count = 5 } } },
  { id = 'furniture_chair', label = 'Cadeira Simples', category = 'furniture', price = 400, contents = { { item = 'chair', count = 1 } } },
  { id = 'electronics_phone', label = 'Telemóvel', category = 'electronics', price = 2000, contents = { { item = 'phone', count = 1 } } },
  { id = 'tools_repairkit', label = 'Repairkit (x2)', category = 'tools', price = 800, contents = { { item = 'repairkit', count = 2 } } },
  { id = 'furniture_table', label = 'Mesa Pequena', category = 'furniture', price = 900, contents = { { item = 'table', count = 1 } } },
  { id = 'furniture_sofa', label = 'Sofá 2 Lugares', category = 'furniture', price = 2500, contents = { { item = 'sofa', count = 1 } } },
  { id = 'furniture_bed', label = 'Cama Casal', category = 'furniture', price = 3200, contents = { { item = 'bed', count = 1 } } },
  { id = 'furniture_lamp', label = 'Candeeiro', category = 'furniture', price = 300, contents = { { item = 'lamp', count = 1 } } },
  -- Variantes e extras
  { id = 'furniture_sofa_small', label = 'Sofá Pequeno', category = 'furniture', price = 1900, contents = { { item = 'sofa_small', count = 1 } } },
  { id = 'furniture_sofa_medium', label = 'Sofá Médio', category = 'furniture', price = 2300, contents = { { item = 'sofa_medium', count = 1 } } },
  { id = 'furniture_bed_double', label = 'Cama Dupla', category = 'furniture', price = 3500, contents = { { item = 'bed_double', count = 1 } } },
  { id = 'furniture_bed_modern', label = 'Cama Moderna', category = 'furniture', price = 3800, contents = { { item = 'bed_modern', count = 1 } } },
  { id = 'furniture_tv', label = 'Televisão', category = 'furniture', price = 2200, contents = { { item = 'tv', count = 1 } } },
  { id = 'furniture_tv_stand', label = 'Móvel de TV', category = 'furniture', price = 1600, contents = { { item = 'tv_stand', count = 1 } } },
  { id = 'furniture_pc_set', label = 'Setup PC (PC+Monitor+Teclado+Rato)', category = 'furniture', price = 4200, contents = { { item = 'pc', count = 1 }, { item = 'monitor', count = 1 }, { item = 'keyboard', count = 1 }, { item = 'mouse', count = 1 } } },
  { id = 'furniture_desk', label = 'Secretária', category = 'furniture', price = 1300, contents = { { item = 'desk', count = 1 } } },
  { id = 'furniture_rug_small', label = 'Tapete Pequeno', category = 'furniture', price = 250, contents = { { item = 'rug_small', count = 1 } } },
  { id = 'furniture_rug_large', label = 'Tapete Grande', category = 'furniture', price = 500, contents = { { item = 'rug_large', count = 1 } } },
  { id = 'furniture_wardrobe', label = 'Guarda-Roupa', category = 'furniture', price = 2400, contents = { { item = 'wardrobe', count = 1 } } },
  { id = 'furniture_bookshelf', label = 'Estante de Livros', category = 'furniture', price = 1500, contents = { { item = 'bookshelf', count = 1 } } },
  { id = 'furniture_shelf', label = 'Prateleira', category = 'furniture', price = 600, contents = { { item = 'shelf', count = 1 } } },
  { id = 'furniture_table_round', label = 'Mesa Redonda', category = 'furniture', price = 1100, contents = { { item = 'table_round', count = 1 } } },
  { id = 'furniture_table_coffee', label = 'Mesa de Centro', category = 'furniture', price = 800, contents = { { item = 'table_coffee', count = 1 } } },
  { id = 'furniture_plant', label = 'Planta', category = 'furniture', price = 350, contents = { { item = 'plant', count = 1 } } },
  { id = 'furniture_lamp_floor', label = 'Candeeiro de Pé', category = 'furniture', price = 450, contents = { { item = 'lamp_floor', count = 1 } } },
}

-- Pagamento ao estafeta por entrega
CommerceConfig.CttPayout = CommerceConfig.CttPayout or { base = 150, distancePerKm = 25 }

-- Distância máxima para entrega em mão (meet)
CommerceConfig.MeetDistance = CommerceConfig.MeetDistance or 10.0
