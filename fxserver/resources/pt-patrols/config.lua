PatrolsConfig = {
  routes = {
    police_city = {
      label = 'Ronda Urbana PSP', job = { 'police', 'psp', 'gnr', 'pj' }, reward = 400,
      points = {
        vector3(440.8, -981.5, 30.7), vector3(266.5, -1107.5, 29.3), vector3(-75.0, -820.0, 326.2), vector3(-623.7, -232.6, 38.1)
      }
    },
    ems_centro = {
      label = 'Ronda INEM Centro', job = { 'ambulance', 'ems', 'inem', 'doctor' }, reward = 350,
      points = {
        vector3(295.0, -584.0, 43.3), vector3(116.0, -744.0, 45.8), vector3(-38.0, -1098.0, 26.4)
      }
    }
  },
  checkpointRadius = 12.0
}
