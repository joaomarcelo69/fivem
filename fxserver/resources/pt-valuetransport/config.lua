
Config = {}

Config.Vehicles = {
    { model = 'stockade', label = 'Carrinha Blindada', minigame = true, npcs = 2 }
}

Config.PickupLocations = {
    { x = 236.5, y = 217.7, z = 106.3, name = 'Banco Central', type = 'bank' },
    { x = 150.2, y = -1040.1, z = 29.3, name = 'ATM Sul', type = 'atm' },
    { x = -1212.9, y = -330.7, z = 37.7, name = 'ATM Norte', type = 'atm' },
    { x = -47.2, y = -1757.5, z = 29.4, name = 'Loja Sul', type = 'shop' }
}

Config.DropLocations = {
    { x = 254.2, y = 225.1, z = 101.9, name = 'Cofre Central', type = 'vault' },
    { x = -2962.6, y = 482.2, z = 15.7, name = 'Cliente VIP', type = 'client' }
}

Config.Job = 'valuetransport'
Config.PoliceJobs = { 'police', 'gnr', 'psp' }
Config.MinEscort = 1
Config.MinValue = 5000
Config.MaxValue = 50000
Config.MissionCooldown = 1800 -- segundos
Config.ContractVIP = true
Config.ContractCooldown = 3600
Config.Reputation = {
    min = 0,
    max = 100,
    bonus = 10,
    penalty = 20
}
Config.Assault = {
    enabled = true,
    minigame = true,
    reward = 0.5, -- percentagem do valor
    policeAlert = true
}
Config.Economy = {
    dynamicATM = true,
    dynamicBank = true,
    shopRequest = true
}
