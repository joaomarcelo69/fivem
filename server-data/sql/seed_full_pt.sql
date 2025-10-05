-- Seeds and extra schema for PT realistic RP

-- ensure core tables
CREATE TABLE IF NOT EXISTS citizens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(128),
  nif VARCHAR(32),
  birth DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vehicle_plates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(32) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vehicles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(32),
  owner_citizenid VARCHAR(64),
  model VARCHAR(128),
  stored BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fines (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(64),
  amount DECIMAL(10,2),
  reason VARCHAR(255),
  paid BOOLEAN DEFAULT FALSE,
  issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- sample citizens
INSERT IGNORE INTO citizens (citizenid, name, nif, birth) VALUES
('PT1001','João Silva','123456789','1985-05-12'),
('PT1002','Maria Fernandes','987654321','1990-07-20'),
('PT1003','Pedro Costa','234567891','1992-11-02');

-- sample plates (PT-like)
INSERT IGNORE INTO vehicle_plates (plate) VALUES
('AA-12-34'),
('BB-56-78'),
('CC-90-12');

-- sample vehicles
INSERT IGNORE INTO vehicles (plate, owner_citizenid, model, stored) VALUES
('AA-12-34','PT1001','Seat Ibiza',FALSE),
('BB-56-78','PT1002','Renault Clio',TRUE);

-- sample fines
INSERT IGNORE INTO fines (citizenid, amount, reason) VALUES
('PT1001',60.00,'Excesso de velocidade'),
('PT1003',120.50,'Estacionamento indevido');
