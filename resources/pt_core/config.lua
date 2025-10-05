-- Configurações PT-PT para recursos do servidor
Config = {}

Config.Country = 'Portugal'
Config.Currency = '€'
Config.SpeedUnit = 'km/h'

-- Placa: formato PT (AA-00-00 ou 00-00-AA variants exist)
Config.PlateFormat = 'PT'

-- Telefones começam por +351 (usamos prefixo local para menus)
Config.PhonePrefix = '+351'

return Config
