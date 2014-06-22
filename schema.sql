
-- ---
-- Globals
-- ---

-- SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- SET FOREIGN_KEY_CHECKS=0;

-- ---
-- Table 'game'
-- 
-- ---

DROP TABLE IF EXISTS `game`;
		
CREATE TABLE `game` (
  `id` INTEGER NOT NULL,
  `matchId` INTEGER NULL DEFAULT NULL,
  `winnerId` INTEGER NULL DEFAULT NULL,
  `dateTime` DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'match'
-- 
-- ---

DROP TABLE IF EXISTS `match`;
		
CREATE TABLE `match` (
  `id` INTEGER NOT NULL,
  `tournamentId` INTEGER NULL DEFAULT NULL,
  `tournamentRound` INTEGER NULL DEFAULT NULL,
  `blueId` INTEGER NULL DEFAULT NULL,
  `redId` INTEGER NULL DEFAULT NULL,
  `winnerId` INTEGER NULL DEFAULT NULL,
  `name` VARCHAR(255) NULL DEFAULT NULL,
  `dateTime` DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'tournament'
-- 
-- ---

DROP TABLE IF EXISTS `tournament`;
		
CREATE TABLE `tournament` (
  `id` INTEGER NOT NULL,
  `name` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'team'
-- 
-- ---

DROP TABLE IF EXISTS `team`;
		
CREATE TABLE `team` (
  `id` INTEGER NOT NULL,
  `name` VARCHAR(255) NULL DEFAULT NULL,
  `acronym` VARCHAR(255) NULL DEFAULT NULL,
  `wins` INTEGER NULL DEFAULT NULL,
  `losses` INTEGER NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'player'
-- 
-- ---

DROP TABLE IF EXISTS `player`;
		
CREATE TABLE `player` (
  `id` INTEGER NOT NULL,
  `name` VARCHAR(255) NULL DEFAULT NULL,
  `role` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'playerGame'
-- 
-- ---

DROP TABLE IF EXISTS `playerGame`;
		
CREATE TABLE `playerGame` (
  `playerId` INTEGER NULL DEFAULT NULL,
  `gameId` INTEGER NULL DEFAULT NULL,
  `kills` INTEGER NULL DEFAULT NULL,
  `deaths` INTEGER NULL DEFAULT NULL,
  `assists` INTEGER NULL DEFAULT NULL,
  `minionKills` INTEGER NULL DEFAULT NULL,
  `doubleKills` INTEGER NULL DEFAULT NULL,
  `tripleKills` INTEGER NULL DEFAULT NULL,
  `quadraKills` INTEGER NULL DEFAULT NULL,
  `pentaKills` INTEGER NULL DEFAULT NULL,
  PRIMARY KEY (`playerId`, `gameId`)
);

-- ---
-- Table 'teamGame'
-- 
-- ---

DROP TABLE IF EXISTS `teamGame`;
		
CREATE TABLE `teamGame` (
  `teamId` INTEGER NULL DEFAULT NULL,
  `gameId` INTEGER NULL DEFAULT NULL,
  `baronsKilled` INTEGER NULL DEFAULT NULL,
  `dragonsKilled` INTEGER NULL DEFAULT NULL,
  `firstBlood` INTEGER NULL DEFAULT NULL,
  `firstTower` INTEGER NULL DEFAULT NULL,
  `firstInhibitor` INTEGER NULL DEFAULT NULL,
  `towersKilled` INTEGER NULL DEFAULT NULL,
  PRIMARY KEY (`teamId`, `gameId`)
);

-- ---
-- Foreign Keys 
-- ---

ALTER TABLE `game` ADD FOREIGN KEY (matchId) REFERENCES `match` (`id`);
ALTER TABLE `match` ADD FOREIGN KEY (tournamentId) REFERENCES `tournament` (`id`);
ALTER TABLE `match` ADD FOREIGN KEY (blueId) REFERENCES `team` (`id`);
ALTER TABLE `match` ADD FOREIGN KEY (redId) REFERENCES `team` (`id`);
ALTER TABLE `match` ADD FOREIGN KEY (winnerId) REFERENCES `team` (`id`);
ALTER TABLE `playerGame` ADD FOREIGN KEY (playerId) REFERENCES `player` (`id`);
ALTER TABLE `playerGame` ADD FOREIGN KEY (gameId) REFERENCES `game` (`id`);
ALTER TABLE `teamGame` ADD FOREIGN KEY (teamId) REFERENCES `team` (`id`);
ALTER TABLE `teamGame` ADD FOREIGN KEY (gameId) REFERENCES `game` (`id`);

-- ---
-- Table Properties
-- ---

-- ALTER TABLE `game` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `match` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `tournament` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `team` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `player` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `playerGame` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
-- ALTER TABLE `teamGame` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

-- ---
-- Initial Data
-- ---

INSERT INTO `team` (`id`,`name`,`acronym`,`wins`,`losses`) VALUES (0,'','',0,0);

-- ---
-- Test Data
-- ---

-- INSERT INTO `game` (`id`,`matchId`,`winnerId`,`dateTime`) VALUES
-- ('','','','');
-- INSERT INTO `match` (`id`,`tournamentId`,`tournamentRound`,`blueId`,`redId`,`winnerId`,`name`,`dateTime`) VALUES
-- ('','','','','','','','');
-- INSERT INTO `tournament` (`id`,`name`) VALUES
-- ('','');
-- INSERT INTO `team` (`id`,`name`,`acronym`,`wins`,`losses`) VALUES
-- ('','','','','');
-- INSERT INTO `player` (`id`,`name`,`role`) VALUES
-- ('','','');
-- INSERT INTO `playerGame` (`playerId`,`gameId`,`kills`,`deaths`,`assists`,`minionKills`,`doubleKills`,`tripleKills`,`quadraKills`,`pentaKills`) VALUES
-- ('','','','','','','','','','');
-- INSERT INTO `teamGame` (`teamId`,`gameId`,`baronsKilled`,`dragonsKilled`,`firstBlood`,`firstTower`,`firstInhibitor`,`towersKilled`) VALUES
-- ('','','','','','','','');

