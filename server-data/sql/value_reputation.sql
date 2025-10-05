-- Tabela para registo de reputação dos jogadores na empresa de valores
CREATE TABLE IF NOT EXISTS value_reputation (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(64),
  reputation INT,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
