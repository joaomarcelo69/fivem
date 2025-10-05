-- Additional seeds for PT RP world
USE qbcore;

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

-- safe commit
COMMIT;
