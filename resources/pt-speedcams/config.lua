SpeedCamsConfig = {
  -- km/h limites por radar fixo
  cameras = {
    { x = -581.1, y = -851.7, z = 25.0, heading = 120.0, limit = 50, zone = 'Urbana' },
    { x = 246.2, y = -1060.5, z = 29.3, heading = 0.0, limit = 50, zone = 'Urbana' },
    { x = -1206.1, y = -1480.8, z = 4.0, heading = 300.0, limit = 70, zone = 'Costeira' },
    { x = 1191.0, y = -1272.2, z = 35.2, heading = 90.0, limit = 80, zone = 'Via Rápida' },
    { x = 2574.3, y = 322.1, z = 108.4, heading = 0.0, limit = 100, zone = 'Auto-estrada' },
  },
  tolerance = 7,      -- tolerância km/h acima do limite
  cooldownSec = 90,   -- tempo entre multas por mesmo radar
  emailWarn = true,
}
