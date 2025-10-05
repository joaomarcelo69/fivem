VehicleDocsConfig = {
  insuranceMonths = 1,
  inspectionMonths = 2,
  baseFines = {
    noInsurance = 500,
    noInspection = 350,
    expired = 150,
  },
  impound = {
    baseFee = 600,
    perDay = 100,
    depot = { x = 409.79, y = -1623.35, z = 29.29, h = 228.0 }, -- parque da PSP/GNR (exemplo), ajustar no mapa
    valet = {
      pedModel = 's_m_y_cop_01',
      driveSpeed = 18.0,
      drivingStyle = 786603, -- normal, respeita regras básicas
      arrivalDist = 12.0,
      timeoutSec = 180
    }
  }
}

-- Postos de atendimento para documentação
VehicleDocsConfig.Offices = VehicleDocsConfig.Offices or {
  insuranceOffice = { x = -75.2, y = -818.5, z = 326.2, h = 160.0 },   -- Maze Bank (andor entrada interior)
  inspectionCenter = { x = 540.4, y = -195.1, z = 54.5, h = 90.0 }     -- Centro técnico (exemplo)
}
