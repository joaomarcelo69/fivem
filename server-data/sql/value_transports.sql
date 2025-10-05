-- Tabela para registo de missões de transporte de valores
CREATE TABLE IF NOT EXISTS value_transports (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pickup VARCHAR(128),
  dropoff VARCHAR(128),
  value INT,
  status VARCHAR(32),
  started_by VARCHAR(64),
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
