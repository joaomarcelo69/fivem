FurnitureConfig = FurnitureConfig or {}

-- Mapeamento de itens para modelos de prop
FurnitureConfig.Items = FurnitureConfig.Items or {
  chair = { label = 'Cadeira', model = `prop_chair_01a`, size = {x=0.6,y=0.6,z=1.0} },
  sofa  = { label = 'Sofá', model = `v_res_mp_sofa`, size = {x=2.2,y=0.9,z=1.0} },
  table = { label = 'Mesa', model = `prop_table_04`, size = {x=1.4,y=1.0,z=0.9} },
  bed   = { label = 'Cama', model = `v_res_d_bed`, size = {x=2.1,y=1.6,z=1.0} },
  lamp  = { label = 'Candeeiro', model = `v_res_d_lampa`, size = {x=0.5,y=0.5,z=1.6} },
  -- Variantes de sofás e camas
  sofa_small  = { label = 'Sofá Pequeno', model = `v_res_tre_sofa_s`, size = {x=1.8,y=0.8,z=1.0} },
  sofa_medium = { label = 'Sofá Médio',   model = `v_res_tre_sofa_m`, size = {x=2.2,y=0.9,z=1.0} },
  bed_double  = { label = 'Cama Dupla',   model = `v_res_mdbed`, size = {x=2.3,y=1.8,z=1.0} },
  bed_modern  = { label = 'Cama Moderna', model = `v_res_tre_bed2`, size = {x=2.1,y=1.7,z=1.0} },
  -- TVs e Suportes
  tv         = { label = 'TV',        model = `prop_tv_flat_01`, size = {x=1.2,y=0.2,z=0.8} },
  tv_stand   = { label = 'Móvel TV',  model = `v_res_tre_tvstand`, size = {x=1.6,y=0.5,z=0.7} },
  -- Setup PC
  pc         = { label = 'PC',        model = `prop_pc_01a`, size = {x=0.6,y=0.4,z=0.5} },
  monitor    = { label = 'Monitor',   model = `prop_monitor_01a`, size = {x=0.7,y=0.2,z=0.6} },
  keyboard   = { label = 'Teclado',   model = `prop_keyboard_01a`, size = {x=0.5,y=0.2,z=0.1} },
  mouse      = { label = 'Rato',      model = `prop_cs_mouse_01`, size = {x=0.2,y=0.2,z=0.1} },
  desk       = { label = 'Secretária', model = `v_res_m_desk`, size = {x=1.8,y=0.8,z=1.2} },
  -- Tapetes
  rug_small  = { label = 'Tapete Pequeno', model = `v_res_rugsmlpile`, size = {x=1.2,y=0.8,z=0.1} },
  rug_large  = { label = 'Tapete Grande',  model = `v_res_rug_big_04`, size = {x=2.6,y=1.8,z=0.1} },
  -- Armários/Guarda-roupa/Estantes
  wardrobe   = { label = 'Guarda-Roupa', model = `v_res_mcupboard`, size = {x=1.7,y=0.7,z=2.0} },
  bookshelf  = { label = 'Estante Livros', model = `prop_bookcase_01`, size = {x=1.2,y=0.5,z=2.0} },
  shelf      = { label = 'Prateleira', model = `v_res_tre_bedsidetable`, size = {x=0.6,y=0.6,z=0.6} },
  -- Mesas extras
  table_round  = { label = 'Mesa Redonda', model = `prop_table_02`, size = {x=1.2,y=1.2,z=0.8} },
  table_coffee = { label = 'Mesa de Centro', model = `v_res_tre_coffeetable`, size = {x=1.1,y=0.6,z=0.5} },
  -- Plantas e iluminação extra
  plant      = { label = 'Planta', model = `prop_plant_int_01a`, size = {x=0.6,y=0.6,z=1.2} },
  lamp_floor = { label = 'Candeeiro de Pé', model = `v_res_m_lampstand`, size = {x=0.6,y=0.6,z=1.8} },
}

-- Distâncias e limites
FurnitureConfig.PlaceMaxDistance = 8.0
FurnitureConfig.ManipulateDistance = 3.0

-- Hook de verificação de posse (casa/quarto/hotel)
-- Substituir por integração com o recurso de habitação quando disponível
function FurnitureConfig.CanDecorate(source, position)
  -- Integração com pt-housing (dono/arrendatário)
  if GetResourceState and GetResourceState('pt-housing') == 'started' then
    local ok, can = pcall(function()
      return exports['pt-housing'] and exports['pt-housing']:CanDecorateAt(source, position) or false
    end)
    if ok and can then return true end
  end
  -- Exemplo: se existir pt-commerce com mailboxes, podes restringir à zona próxima da caixa do jogador
  if GetResourceState and GetResourceState('pt-commerce') == 'started' then
    local exportOK, mailboxFor = pcall(function()
      return exports['pt-commerce'] and exports['pt-commerce'].GetMailboxFor or nil
    end)
    if exportOK and mailboxFor then
      local mb = mailboxFor(source)
      if mb and mb.coords then
        local dx = (position.x - mb.coords.x)
        local dy = (position.y - mb.coords.y)
        local dz = (position.z - (mb.coords.z or position.z))
        return (dx*dx + dy*dy + dz*dz) <= (20.0*20.0)
      end
    end
  end
  -- fallback permissivo
  return true
end
