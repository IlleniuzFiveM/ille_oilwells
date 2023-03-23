CREATE TABLE IF NOT EXISTS `oilwells` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL UNIQUE,
    `owner` VARCHAR(255) DEFAULT NULL,
    `money_generated` DECIMAL(10, 2) NOT NULL DEFAULT 0
);

INSERT INTO `oilwells` (`name`) VALUES
    ('oiwell11'),
    ('oiwell12'),
    ('oiwell113'),
    ('oiwell114');
