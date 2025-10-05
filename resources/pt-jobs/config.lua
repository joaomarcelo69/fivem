-- Catálogo de empregos PT (IDs devem existir em qb-core/shared/jobs.lua)
PT_JOBS = {
  -- Serviços de emergência
  { id = 'police', label = 'Polícia', baseSalary = 1200 },
  { id = 'ambulance', label = 'INEM', baseSalary = 1100 },
  { id = 'bombeiros', label = 'Bombeiros', baseSalary = 900 },
  { id = 'psp', label = 'PSP', baseSalary = 1200 },
  { id = 'gnr', label = 'GNR', baseSalary = 1200 },
  { id = 'pj', label = 'Polícia Judiciária', baseSalary = 1300 },
  -- Transporte
  { id = 'taxi', label = 'Táxi', baseSalary = 600 },
  { id = 'bus', label = 'Carreiras', baseSalary = 550 },
  { id = 'trucker', label = 'Camiões', baseSalary = 650 },
  { id = 'tvde', label = 'TVDE', baseSalary = 650 },
  -- Oficinas
  { id = 'mechanic', label = 'Mecânico', baseSalary = 700 },
  { id = 'mechanic2', label = 'Mecânico (Hayes)', baseSalary = 700 },
  { id = 'mechanic3', label = 'Mecânico (Sandy/Paleto)', baseSalary = 700 },
  { id = 'beeker', label = "Beeker's Garage", baseSalary = 700 },
  { id = 'bennys', label = "Benny's", baseSalary = 700 },
  -- Serviços
  { id = 'garbage', label = 'Lixo', baseSalary = 500 },
  { id = 'vineyard', label = 'Vinha', baseSalary = 500 },
  { id = 'hotdog', label = 'Cachorros', baseSalary = 450 },
  { id = 'reporter', label = 'Jornalista', baseSalary = 550 },
  { id = 'ctt', label = 'CTT', baseSalary = 600 },
  { id = 'pescador', label = 'Pescador', baseSalary = 500 },
  { id = 'mineiro', label = 'Mineiro', baseSalary = 550 },
  -- Negócios
  { id = 'realestate', label = 'Imobiliária', baseSalary = 800 },
  { id = 'cardealer', label = 'Stand', baseSalary = 800 },
  -- Justiça
  { id = 'judge', label = 'Juiz', baseSalary = 1000 },
  { id = 'lawyer', label = 'Advogado', baseSalary = 900 },
}

-- Jobs padrão que todo o jogador tem
PT_UNEMPLOYED = { id = 'unemployed', label = 'Desempregado', baseSalary = 10 }
