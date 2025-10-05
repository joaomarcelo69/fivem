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
