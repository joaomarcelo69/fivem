-- Ensure qbcore user and grants
CREATE DATABASE IF NOT EXISTS qbcore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'qbcore'@'%' IDENTIFIED BY 'qbcore_pass';
CREATE USER IF NOT EXISTS 'qbcore'@'localhost' IDENTIFIED BY 'qbcore_pass';
GRANT ALL PRIVILEGES ON qbcore.* TO 'qbcore'@'%';
GRANT ALL PRIVILEGES ON qbcore.* TO 'qbcore'@'localhost';
FLUSH PRIVILEGES;
