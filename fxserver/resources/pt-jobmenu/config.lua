JobDutyZones = JobDutyZones or {
  police = {
    { coords = vector3(441.2, -982.0, 30.7), radius = 30.0, label = 'MRPD - Centro' },
    { coords = vector3(-1108.4, -844.1, 19.0), radius = 25.0, label = 'Vespucci PD' },
    { coords = vector3(379.6, -1597.6, 29.3), radius = 25.0, label = 'Davis PD' },
    { coords = vector3(1853.1, 3690.5, 34.2), radius = 25.0, label = 'Sandy Shores Sheriff' },
    { coords = vector3(-447.1, 6012.8, 31.7), radius = 25.0, label = 'Paleto Bay Sheriff' },
  },
  psp = {
    { coords = vector3(441.2, -982.0, 30.7), radius = 30.0, label = 'PSP - MRPD' },
    { coords = vector3(-1108.4, -844.1, 19.0), radius = 25.0, label = 'PSP - Vespucci' },
    { coords = vector3(379.6, -1597.6, 29.3), radius = 25.0, label = 'PSP - Davis' },
  },
  gnr = {
    { coords = vector3(1853.1, 3690.5, 34.2), radius = 25.0, label = 'GNR - Sandy' },
    { coords = vector3(-447.1, 6012.8, 31.7), radius = 25.0, label = 'GNR - Paleto' },
  },
  pj = {
    { coords = vector3(-546.3, -202.0, 38.2), radius = 20.0, label = 'PJ - Sede' },
  },
  ambulance = {
    { coords = vector3(311.2, -597.3, 43.3), radius = 30.0, label = 'Pillbox Hospital' },
    { coords = vector3(1835.6, 3675.8, 34.3), radius = 25.0, label = 'Sandy Medical' },
    { coords = vector3(-247.5, 6331.6, 32.4), radius = 25.0, label = 'Paleto Medical' },
  },
  bombeiros = {
    { coords = vector3(215.0, -1643.1, 29.8), radius = 25.0, label = 'BV Lisboa' },
    { coords = vector3(-635.6, -121.6, 38.0), radius = 25.0, label = 'BV Centro' },
  },
  taxi = {
    { coords = vector3(903.0, -172.5, 74.1), radius = 25.0, label = 'Downtown Cab Co.' },
    { coords = vector3(-286.2, -887.1, 31.1), radius = 20.0, label = 'Alta Ponto Taxi' },
    { coords = vector3(-1022.1, -2731.8, 13.8), radius = 20.0, label = 'LSIA Ponto Taxi' },
  },
  tvde = {
    { coords = vector3(-161.3, -981.6, 30.2), radius = 25.0, label = 'Hub TVDE' },
    { coords = vector3(-540.4, -213.6, 37.7), radius = 20.0, label = 'TVDE Centro' },
  },
  cardealer = {
    { coords = vector3(-56.7, -1096.6, 26.4), radius = 25.0, label = 'PDM' },
    { coords = vector3(-795.5, -220.8, 37.0), radius = 20.0, label = 'Luxury Autos' },
  },
  realestate = {
    { coords = vector3(-707.4, -904.0, 19.2), radius = 20.0, label = 'Dynasty 8' },
    { coords = vector3(-125.9, -641.1, 168.8), radius = 20.0, label = 'Vinewood Office' },
  },
  reporter = {
    { coords = vector3(-598.8, -929.9, 23.9), radius = 25.0, label = 'Weazel News' },
    { coords = vector3(-1050.1, -230.5, 44.0), radius = 20.0, label = 'Rockford Studio' },
  },
  tow = {
    { coords = vector3(409.3, -1623.1, 29.3), radius = 30.0, label = 'Impound LS' },
    { coords = vector3(1717.8, 3718.1, 34.1), radius = 25.0, label = 'Impound Sandy' },
    { coords = vector3(-199.2, 6225.4, 31.5), radius = 25.0, label = 'Impound Paleto' },
  },
  garbage = {
    { coords = vector3(-349.5, -1569.1, 25.2), radius = 30.0, label = 'Sanitation LS' },
    { coords = vector3(1549.9, 6322.2, 24.1), radius = 25.0, label = 'Sanitation Grapeseed' },
  },
  vineyard = {
    { coords = vector3(-1886.0, 2049.0, 140.98), radius = 30.0, label = 'Vinha Principal' },
    { coords = vector3(-1883.5, 2090.6, 140.0), radius = 20.0, label = 'Armazém Vinha' },
  },
  bus = {
    { coords = vector3(436.5, -645.9, 28.7), radius = 25.0, label = 'Terminal Central' },
    { coords = vector3(-254.7, 6066.0, 31.4), radius = 20.0, label = 'Paragem Paleto' },
  },
  hotdog = {
    { coords = vector3(38.0, -1003.5, 29.3), radius = 20.0, label = 'Centro Vendas' },
    { coords = vector3(-1322.6, -389.2, 36.6), radius = 20.0, label = 'Rockford Vendas' },
  },
  ctt = {
    { coords = vector3(120.6, -3022.3, 7.0), radius = 30.0, label = 'Armazém CTT' },
    { coords = vector3(-423.6, -2784.4, 6.0), radius = 25.0, label = 'Doca CTT' },
  },
  pescador = {
    { coords = vector3(-1593.1, 5252.6, 3.9), radius = 30.0, label = 'Porto de Pesca' },
  },
  mineiro = {
    { coords = vector3(2947.1, 2744.6, 43.5), radius = 30.0, label = 'Mina' },
    { coords = vector3(1109.6, -2007.4, 31.0), radius = 25.0, label = 'Processamento' },
  },
  mechanic = {
    { coords = vector3(-205.7, -1311.3, 31.3), radius = 25.0, label = 'Benny\'s' },
    { coords = vector3(732.0, -1088.9, 22.2), radius = 25.0, label = 'LSC Popular St.' },
  },
  mechanic2 = {
    { coords = vector3(-1417.0, -445.9, 35.9), radius = 25.0, label = 'Hayes Auto' },
  },
  mechanic3 = {
    { coords = vector3(1174.7, 2639.6, 37.8), radius = 25.0, label = 'Sandy Mech' },
  },
  beeker = {
    { coords = vector3(116.7, 6624.2, 31.8), radius = 25.0, label = 'Beeker\'s Garage' },
  },
  bennys = {
    { coords = vector3(-205.7, -1311.3, 31.3), radius = 25.0, label = 'Benny\'s' },
  },
  judge = {
    { coords = vector3(233.2, -410.3, 48.1), radius = 20.0, label = 'Tribunal' },
  },
  lawyer = {
    { coords = vector3(233.2, -410.3, 48.1), radius = 20.0, label = 'Tribunal' },
  },
  trucker = {
    { coords = vector3(902.0, -3231.0, 5.9), radius = 35.0, label = 'Doca LS' },
    { coords = vector3(132.2, 6625.9, 31.8), radius = 25.0, label = 'Doca Paleto' },
  },
}

JobRoutes = JobRoutes or {
  taxi = {
    { x = -158.6, y = -981.2, z = 30.2 },
    { x = -75.3, y = -818.6, z = 326.2 },
    { x = 266.1, y = -375.1, z = 44.8 },
    { x = -673.0, y = -1096.9, z = 14.6 },
  },
  bus = {
    { x = -1037.6, y = -2731.3, z = 13.8 },
    { x = -322.3, y = -936.9, z = 31.1 },
    { x = 251.8, y = -1071.2, z = 29.3 },
    { x = 195.1, y = -1651.8, z = 29.8 },
  },
  trucker = {
    { x = 905.3, y = -3230.7, z = 5.9 },
    { x = -310.8, y = -1353.2, z = 31.3 },
    { x = -425.1, y = -2795.0, z = 6.0 },
    { x = 1216.0, y = -2975.0, z = 5.9 },
  },
  garbage = {
    { x = -321.8, y = -1545.9, z = 27.5 },
    { x = -298.3, y = -1343.3, z = 31.3 },
    { x = 373.1, y = -1283.7, z = 32.5 },
    { x = 736.3, y = -1347.1, z = 26.2 },
    { x = 1170.8, y = -1544.6, z = 39.4 },
  },
  tvde = {
    { x = -158.6, y = -981.2, z = 30.2 },
    { x = 266.1, y = -375.1, z = 44.8 },
    { x = -673.0, y = -1096.9, z = 14.6 },
    { x = -1022.1, y = -2731.8, z = 13.8 },
  },
  ctt = {
    { x = 120.6, y = -3022.3, z = 7.0 },
    { x = -423.6, y = -2784.4, z = 6.0 },
    { x = 905.3, y = -3230.7, z = 5.9 },
    { x = -310.8, y = -1353.2, z = 31.3 },
  },
  pescador = {
    { x = -1593.1, y = 5252.6, z = 3.9 },
    { x = -1616.9, y = 5262.7, z = 3.9 },
    { x = -1628.2, y = 5260.4, z = 3.9 },
    { x = -1609.4, y = 5249.9, z = 3.9 },
  },
  mineiro = {
    { x = 2947.1, y = 2744.6, z = 43.5 },
    { x = 2964.2, y = 2753.8, z = 43.6 },
    { x = 2977.5, y = 2754.3, z = 43.7 },
    { x = 2959.8, y = 2738.1, z = 43.4 },
  },
}

RoutePayouts = RoutePayouts or {
  taxi = { per = 75, bonus = 150 },
  bus = { per = 100, bonus = 250 },
  trucker = { per = 150, bonus = 400 },
  garbage = { per = 90, bonus = 200 },
  tvde = { per = 80, bonus = 180 },
  ctt = { per = 110, bonus = 300 },
  pescador = { per = 95, bonus = 220 },
  mineiro = { per = 120, bonus = 320 },
}

PolicePropModels = PolicePropModels or {
  cone = 'prop_roadcone02a',
  barrier = 'prop_barrier_work05',
  spikes = 'p_ld_stinger_s',
}

EMSConfig = EMSConfig or {
  enableBasicRevive = true,
  enableBasicStabilize = true,
}

DutyInteractKey = DutyInteractKey or 38
DutyInteractName = DutyInteractName or 'E'

JobVehicleSpawns = JobVehicleSpawns or {
  
  police = {
    { coords = vector3(446.3, -991.7, 25.7), heading = 90.0, label = 'MRPD - Garagem' },
    { coords = vector3(373.2, -1611.6, 29.3), heading = 50.0, label = 'Davis PD - Garagem' },
  },
  psp = {
    { coords = vector3(446.3, -991.7, 25.7), heading = 90.0, label = 'PSP - Garagem MRPD' },
    { coords = vector3(-1045.5, -856.7, 4.9), heading = 215.0, label = 'PSP - Garagem Vespucci' },
    { coords = vector3(373.2, -1611.6, 29.3), heading = 50.0, label = 'PSP - Garagem Davis' },
  },
  gnr = {
    { coords = vector3(1866.0, 3692.5, 33.8), heading = 210.0, label = 'GNR - Garagem Sandy' },
    { coords = vector3(-442.4, 6021.1, 31.5), heading = 45.0, label = 'GNR - Garagem Paleto' },
  },
  pj = {
    { coords = vector3(-555.1, -203.5, 38.2), heading = 120.0, label = 'PJ - Garagem' },
  },
  
  ambulance = {
    { coords = vector3(294.4, -601.2, 43.3), heading = 70.0, label = 'Pillbox - Garagem' },
  },
  bombeiros = {
    { coords = vector3(209.5, -1656.1, 29.8), heading = 48.0, label = 'Bombeiros - Davis' },
  },
  
  taxi = {
    { coords = vector3(900.0, -178.0, 73.0), heading = 240.0, label = 'DCC - Garagem' },
  },
  tvde = {
    { coords = vector3(-157.0, -978.0, 30.2), heading = 180.0, label = 'Hub TVDE - Garagem' },
  },
  bus = {
    { coords = vector3(436.0, -651.0, 28.7), heading = 90.0, label = 'Terminal de Autocarros' },
  },
  trucker = {
    { coords = vector3(905.3, -3230.7, 5.9), heading = 90.0, label = 'Doca LS - Garagem' },
  },
  tow = {
    { coords = vector3(409.3, -1623.1, 29.3), heading = 318.0, label = 'Parque de Reboque' },
  },
  garbage = {
    { coords = vector3(-349.5, -1569.1, 25.2), heading = 230.0, label = 'Sanitation LS' },
  },
  
  mechanic = {
    { coords = vector3(733.0, -1081.5, 22.2), heading = 90.0, label = 'LSC Popular' },
  },
  mechanic2 = {
    { coords = vector3(-1420.0, -453.0, 35.9), heading = 120.0, label = 'Hayes Auto' },
  },
  mechanic3 = {
    { coords = vector3(1177.0, 2635.0, 37.8), heading = 0.0, label = 'Sandy Mech' },
  },
  beeker = {
    { coords = vector3(116.7, 6624.2, 31.8), heading = 315.0, label = 'Beeker\'s' },
  },
  bennys = {
    { coords = vector3(-205.7, -1311.3, 31.3), heading = 270.0, label = 'Benny\'s' },
  },
  
  reporter = {
    { coords = vector3(-598.8, -929.9, 23.9), heading = 270.0, label = 'Weazel News' },
  },
  cardealer = {
    { coords = vector3(-44.0, -1095.0, 26.0), heading = 70.0, label = 'PDM' },
  },
  realestate = {
    { coords = vector3(-710.0, -903.0, 19.2), heading = 0.0, label = 'Dynasty 8' },
  },
  
  vineyard = {
    { coords = vector3(-1889.0, 2054.0, 140.95), heading = 210.0, label = 'Vinha' },
  },
  hotdog = {
    { coords = vector3(38.0, -1006.0, 29.3), heading = 0.0, label = 'Carrinho Hotdog' },
  },
  ctt = {
    { coords = vector3(120.6, -3022.3, 7.0), heading = 270.0, label = 'Armazém CTT' },
  },
  pescador = {
    { coords = vector3(-1601.0, 5253.0, 1.0), heading = 20.0, label = 'Porto de Pesca' },
  },
  mineiro = {
    { coords = vector3(2947.1, 2744.6, 43.5), heading = 200.0, label = 'Mina' },
  },
}

AllowedJobVehicles = AllowedJobVehicles or {
  
  police = { 'police', 'police2', 'police3' },
  psp    = { 'police', 'police2', 'police3' },
  gnr    = { 'sheriff', 'sheriff2', 'pranger' },
  pj     = { 'police4', 'fbi', 'fbi2' },
  
  ambulance = { 'ambulance' },
  bombeiros = { 'firetruk' },
  
  taxi    = { 'taxi' },
  tvde    = { 'premier', 'asterope', 'intruder' },
  bus     = { 'bus', 'coach' },
  trucker = { 'mule', 'benson' },
  tow     = { 'towtruck', 'towtruck2' },
  garbage = { 'trash', 'trash2' },
  
  mechanic  = { 'utillitruck3', 'towtruck2' },
  mechanic2 = { 'utillitruck3', 'towtruck2' },
  mechanic3 = { 'utillitruck3', 'towtruck2' },
  beeker    = { 'utillitruck3', 'towtruck2' },
  bennys    = { 'utillitruck3', 'towtruck2' },
  
  reporter   = { 'rumpo', 'speedo' },
  cardealer  = { 'oracle', 'asea' },
  realestate = { 'tailgater', 'premier' },
  
  vineyard = { 'tractor2', 'bison' },
  hotdog   = { 'taco' },
  ctt      = { 'boxville', 'pony' },
  pescador = { 'dinghy', 'tropic' },
  mineiro  = { 'bobcatxl', 'rebel' },
}

SpeedLimits = SpeedLimits or {
  { coords = vector3(250.0, -1000.0, 28.0), radius = 1000.0, limit = 50 },   
  { coords = vector3(380.0, -1600.0, 29.0), radius = 800.0,  limit = 50 },   
  { coords = vector3(-1200.0, -900.0, 12.0), radius = 900.0, limit = 60 },   
  { coords = vector3(-300.0, -2000.0, 20.0), radius = 1200.0, limit = 80 },  
  { coords = vector3(1600.0, -1000.0, 60.0), radius = 2000.0, limit = 100 }, 
  { coords = vector3(-900.0, -1600.0, 13.0), radius = 1500.0, limit = 100 }, 
  { coords = vector3(1400.0, 4500.0, 40.0), radius = 2000.0, limit = 90 },   
  { coords = vector3(-1700.0, -300.0, 50.0), radius = 1500.0, limit = 120 }, 
}
DefaultSpeedLimit = DefaultSpeedLimit or 90
