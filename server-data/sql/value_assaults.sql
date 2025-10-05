-- Tabela para registo de assaltos às carrinhas de valores
CREATE TABLE IF NOT EXISTS value_assaults (
  id INT AUTO_INCREMENT PRIMARY KEY,
  transport_id INT,
  assailant VARCHAR(64),
  reward INT,
  result VARCHAR(32),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
