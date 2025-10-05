FireConfig = {
  incidents = {
    car = { min = 1, max = 3 },
    house = { min = 1, max = 2 }
  },
  cooldownSec = 300,
  extinguisherItem = 'weapon_fireextinguisher',
  medkitItem = 'medkit',
  stations = {
    {
      label = 'Quartel Davis',
      locker = { x = -633.8, y = -124.2, z = 39.01 },
      garage = { x = -635.9, y = -104.9, z = 38.0, h = 90.0 },
      vehicles = {
        { label = 'Camião Bombeiros', model = 'firetruk', livery = 0, color1 = {255,0,0}, color2 = {255,255,255}, extras = {}, platePrefix = 'BV' },
        { label = 'Ambulância INEM', model = 'ambulance', livery = 0, color1 = {255,220,0}, color2 = {0,60,160}, extras = {}, platePrefix = 'IN' },
      }
    },
    {
      label = 'Quartel Sandy Shores',
      locker = { x = 1690.9, y = 3581.1, z = 35.62 },
      garage = { x = 1697.6, y = 3586.5, z = 35.62, h = 210.0 },
      vehicles = {
        { label = 'Camião Bombeiros', model = 'firetruk', livery = 0, color1 = {255,0,0}, color2 = {255,255,255}, extras = {}, platePrefix = 'BV' },
        { label = 'Ambulância INEM', model = 'ambulance', livery = 0, color1 = {255,220,0}, color2 = {0,60,160}, extras = {}, platePrefix = 'IN' },
      }
    },
    {
      label = 'Quartel Paleto Bay',
      locker = { x = -374.8, y = 6117.9, z = 31.85 },
      garage = { x = -379.4, y = 6118.8, z = 31.85, h = 45.0 },
      vehicles = {
        { label = 'Camião Bombeiros', model = 'firetruk', livery = 0, color1 = {255,0,0}, color2 = {255,255,255}, extras = {}, platePrefix = 'BV' },
        { label = 'Ambulância INEM', model = 'ambulance', livery = 0, color1 = {255,220,0}, color2 = {0,60,160}, extras = {}, platePrefix = 'IN' },
      }
    }
  },
  hydrants = {
    { x = -632.6, y = -123.0, z = 39.0 },
    { x = -640.2, y = -110.6, z = 38.8 },
    { x = 1695.9, y = 3583.8, z = 35.6 },
    { x = -382.1, y = 6122.0, z = 31.9 },
    { x = 215.5, y = -1646.7, z = 29.7 },
    { x = -1085.0, y = -846.3, z = 19.0 }
  },
  houseSafeOffset = { x = 8.0, y = 8.0, z = 0.0 },
  hospitals = {
    { x = 295.0, y = -584.0, z = 43.3 }, -- Pillbox
    { x = 1839.0, y = 3672.0, z = 34.3 }, -- Sandy
    { x = -247.4, y = 6326.3, z = 32.4 } -- Paleto
  },
  outfits = {
    male = {
      components = {
        { id = 3, drawable = 1, texture = 0 },   -- arms
        { id = 4, drawable = 47, texture = 0 },  -- legs
        { id = 6, drawable = 25, texture = 0 },  -- shoes
        { id = 8, drawable = 15, texture = 0 },  -- undershirt
        { id = 11, drawable = 66, texture = 0 }, -- jacket
      },
      props = {
        -- { id = 0, drawable = 13, texture = 0 } -- helmet opcional
      }
    },
    female = {
      components = {
        { id = 3, drawable = 1, texture = 0 },
        { id = 4, drawable = 48, texture = 0 },
        { id = 6, drawable = 25, texture = 0 },
        { id = 8, drawable = 15, texture = 0 },
        { id = 11, drawable = 66, texture = 0 },
      },
      props = {}
    }
  }
}
