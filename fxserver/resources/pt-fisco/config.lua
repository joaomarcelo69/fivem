FiscoConfig = FiscoConfig or {
  Regiao = 'continente', 
  
  IVACategorias = {
    
    continente = { normal = 0.23, interm = 0.13, reduzido = 0.06 },
    madeira = { normal = 0.22, interm = 0.12, reduzido = 0.05 },
    acores = { normal = 0.16, interm = 0.09, reduzido = 0.04 },
  },
  
  IVAMap = {
    vendas = 'normal',
    alimentacao = 'reduzido',
    restauracao = 'interm',
    combustivel = 'normal',
  },
  
  IRS = {
    trabalho = 0.11,   
    servicos = 0.15,   
    vendas = 0.00,     
    multas = 0.00,     
  },
  Enable = {
    IVA = true,
    IRS = true,
    Persistencia = true,
  },
  
  IMT = {
    
    
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
    Rate = 0.008 
  },
  IMI = {
    AnnualRate = 0.003 
  }
}
