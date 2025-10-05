Config = {}

Config.Vehicles = {
    { model = 'stockade', label = 'Carrinha Blindada', minigame = true }
}

Config.PickupLocations = {
    { x = 236.5, y = 217.7, z = 106.3, name = 'Banco Central' },
    { x = 150.2, y = -1040.1, z = 29.3, name = 'ATM Sul' },
    { x = -1212.9, y = -330.7, z = 37.7, name = 'ATM Norte' }
}

Config.DropLocations = {
    { x = 254.2, y = 225.1, z = 101.9, name = 'Cofre Central' },
    { x = -2962.6, y = 482.2, z = 15.7, name = 'Cliente VIP' }
}

Config.Job = 'valuetransport'
Config.PoliceJobs = { 'police', 'gnr', 'psp' }
Config.MinEscort = 1
Config.MinValue = 5000
Config.MaxValue = 50000
Config.MissionCooldown = 1800 -- segundos
