-- Tabela para registo de contratos VIP de transporte de valores
CREATE TABLE IF NOT EXISTS value_contracts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client VARCHAR(128),
  value INT,
  status VARCHAR(32),
  assigned_to VARCHAR(64),
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
