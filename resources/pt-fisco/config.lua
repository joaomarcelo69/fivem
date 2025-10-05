FiscoConfig = FiscoConfig or {
  Regiao = 'continente', -- 'continente' | 'madeira' | 'acores'
  -- IVA por categoria (Portugal)
  IVACategorias = {
    -- Continente: 23/13/6
    continente = { normal = 0.23, interm = 0.13, reduzido = 0.06 },
    madeira = { normal = 0.22, interm = 0.12, reduzido = 0.05 },
    acores = { normal = 0.16, interm = 0.09, reduzido = 0.04 },
  },
  -- Mapeamento de categorias por tipo de venda
  IVAMap = {
    vendas = 'normal',
    alimentacao = 'reduzido',
    restauracao = 'interm',
    combustivel = 'normal',
  },
  -- IRS withholding (simplificado)
  IRS = {
    trabalho = 0.11,   -- salários/rotas
    servicos = 0.15,   -- serviços
    vendas = 0.00,     -- vendas não retêm ao vendedor
    multas = 0.00,     -- multas não retêm IRS ao agente
  },
  Enable = {
    IVA = true,
    IRS = true,
    Persistencia = true,
  },
  -- Impostos patrimoniais (simplificado para gameplay)
  IMT = {
    -- Tabela simplificada por escalões (percentagem aplicada ao valor total)
    -- NOTA: isto é para gameplay, não segue à risca as tabelas oficiais
    Brackets = {
      { upTo = 100000, rate = 0.00 },
      { upTo = 150000, rate = 0.02 },
      { upTo = 250000, rate = 0.05 },
      { upTo = 500000, rate = 0.07 },
      { upTo = 1000000, rate = 0.08 },
      { upTo = math.huge, rate = 0.10 },
    },
  },
  ImpostoSelo = {
    Rate = 0.008 -- 0.8%
  },
  IMI = {
    AnnualRate = 0.003 -- 0.3%/ano sobre o valor base (preço)
  }
}
