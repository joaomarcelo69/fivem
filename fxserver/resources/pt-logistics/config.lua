LogiConfig = LogiConfig or {}

LogiConfig.ImportHubs = {
  { id='porto', label='Porto de Carga', coords=vector3(-278.48, -2656.57, 6.0) },
  { id='aeroporto', label='Aeroporto Carga', coords=vector3(-1035.42, -2737.64, 13.8) }
}

LogiConfig.Warehouse = { id='central', label='Armazém Central', coords=vector3(1061.9, -3109.5, -40.0) }

LogiConfig.VehicleCapacity = {
  truck = 1000,   
  van = 250       
}

LogiConfig.Products = {
  { sku='agua_palet', label='Palete de Água', yields = { { item='water', count=100 } } },
  { sku='pao_caixa', label='Caixa de Pão', yields = { { item='bread', count=100 } } },
  { sku='eletronica_mista', label='Lote Electrónica', yields = { { item='phone', count=10 }, { item='radio', count=20 } } }
}

LogiConfig.ShopWhitelist = {} 

LogiConfig.MinStock = {
  water = 50,
  bread = 50,
  phone = 5,
  radio = 10
}

LogiConfig.LoadingTimes = {
  import_truck = 30,   
  route_van = 15,      
  route_truck = 30     
}

LogiConfig.NPC = {
  enabled = true,
  checkIntervalSeconds = 120,      
  minLastDeliverySeconds = 1800     
}
