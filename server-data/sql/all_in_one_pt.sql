-- All-in-one SQL for QBCore PT setup
-- Ordem: schema mínimo -> schema PT -> seeds -> seeds extra -> migração compatibilidade

-- =============== qbcore_min_schema.sql ===============
-- Minimal QBCore-compatible schema: inventories, items, inventory_items (mapping), players

CREATE TABLE IF NOT EXISTS `players` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `citizenid` VARCHAR(64) NOT NULL UNIQUE,
  `name` VARCHAR(128),
  `money` INT DEFAULT 0,
  `bank` INT DEFAULT 0,
  `job` VARCHAR(64),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `inventories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(128) NOT NULL UNIQUE,
  `owner` VARCHAR(128),
  `type` VARCHAR(32),
  `slots` INT DEFAULT 30,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(128) NOT NULL UNIQUE,
  `label` VARCHAR(128),
  `stackable` BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `inventory_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `inventory_id` VARCHAR(128) NOT NULL,
  `item` VARCHAR(128) NOT NULL,
  `count` INT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uniq_inventory_item` (`inventory_id`,`item`),
  KEY(`inventory_id`),
  KEY(`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- minimal seed
INSERT IGNORE INTO items (name, label, stackable) VALUES
('bread', 'Pão', TRUE),
('water', 'Água', TRUE),
('phone', 'Telemóvel', FALSE),
('dirty_money', 'Dinheiro Sujo', TRUE);

INSERT IGNORE INTO inventories (name, owner, type, slots) VALUES
('players_inventory_PT1001','PT1001','player',40),
('players_inventory_PT1002','PT1002','player',40);

INSERT IGNORE INTO players (citizenid, name, money, bank, job) VALUES
('PT1001','João Silva',200,500,'unemployed'),
('PT1002','Maria Fernandes',150,300,'unemployed');

INSERT IGNORE INTO inventory_items (inventory_id, item, count) VALUES
('players_inventory_PT1001','bread',3),
('players_inventory_PT1001','water',2),
('players_inventory_PT1002','phone',1);

-- =============== pt_schema.sql ===============
-- Schema inicial para recursos PT (oxmysql)

CREATE TABLE IF NOT EXISTS vehicle_plates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(32) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS citizens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(128),
  nif VARCHAR(32),
  birth DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS driving_licenses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(64) NOT NULL,
  license_type VARCHAR(8),
  issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============== seed_full_pt.sql ===============
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

-- =============== seed_more_pt.sql ===============
-- Additional seeds for PT RP world

-- Nota: se necessário, descomenta a próxima linha quando importares fora do contexto da DB selecionada
-- USE qbcore;

-- More citizens (use `name` and `birth` columns)
INSERT IGNORE INTO citizens (citizenid, name, birth) VALUES
('PT1003','Ana Silva','1992-04-12'),
('PT1004','Miguel Costa','1985-11-03'),
('PT1005','Sofia Pereira','1999-07-21');

-- More vehicle plates (unique)
INSERT IGNORE INTO vehicle_plates (plate) VALUES
('PT-AN-03'),
('PT-MI-04'),
('PT-SO-05');

-- More vehicles (use owner_citizenid column)
INSERT IGNORE INTO vehicles (plate, owner_citizenid, model, stored) VALUES
('PT-AN-03','PT1003','seat_ibiza',0),
('PT-MI-04','PT1004','renault_clio',0),
('PT-SO-05','PT1005','fiat_panda',0);

-- Add shop NPCs (simple table: shops_npcs) - create table if not exists
CREATE TABLE IF NOT EXISTS shops_npcs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shop_id VARCHAR(128),
  x DOUBLE,
  y DOUBLE,
  z DOUBLE,
  heading DOUBLE
);

INSERT IGNORE INTO shops_npcs (shop_id, x, y, z, heading) VALUES
('Lisboa_Shop_1',373.9,325.8,103.5,90.0),
('Lisboa_24_7_1',1960.5,3741.8,32.3,180.0),
('Lisboa_Market_1',-712.1,-919.4,19.2,270.0),
('Porto_Shop_1',-707.2,-914.2,19.2,90.0),
('Porto_Market_1',-560.3,-1200.7,17.4,135.0);

-- Example fines / notes to add world activity
INSERT IGNORE INTO fines (citizenid, amount, reason) VALUES
('PT1003',120,'Excesso de velocidade'),
('PT1004',80,'Estacionamento proibido');

-- safe commit (no-op if autocommit)
COMMIT;

-- =============== migrate_inventory_items_compat.sql ===============
-- Migration: align inventory_items columns with resource usage
-- Nota: alguns motores não suportam IF NOT EXISTS em ALTER; ignora se der warning
ALTER TABLE inventory_items
  ADD COLUMN IF NOT EXISTS inventory_id VARCHAR(128) NULL,
  ADD COLUMN IF NOT EXISTS item VARCHAR(128) NULL;

-- Backfill from legacy columns if present
UPDATE inventory_items
SET inventory_id = COALESCE(inventory_id, inventory_name),
    item = COALESCE(item, item_name)
WHERE (inventory_id IS NULL OR item IS NULL);

-- Add unique composite key for upsert logic
ALTER TABLE inventory_items
  ADD UNIQUE KEY IF NOT EXISTS uniq_inventory_item (inventory_id, item);
