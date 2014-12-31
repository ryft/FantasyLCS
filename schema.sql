
-- ---
-- Globals
-- ---

-- SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- SET FOREIGN_KEY_CHECKS=0;

-- ---
-- Table 'League'
-- 
-- ---

DROP TABLE IF EXISTS `League`;
        
CREATE TABLE `League` (
  `id` INTEGER NOT NULL,
  `color` VARCHAR(255) NULL DEFAULT NULL,
  `leagueImage` VARCHAR(255) NULL DEFAULT NULL,
  `defaultTournamentId` INTEGER NULL DEFAULT NULL,
  `defaultSeriesId` INTEGER NULL DEFAULT NULL,
  `shortName` VARCHAR(255) NULL DEFAULT NULL,
  `url` VARCHAR(255) NULL DEFAULT NULL,
  `label` VARCHAR(255) NULL DEFAULT NULL,
  `noVods` TINYINT NULL DEFAULT NULL,
  `menuWeight` INTEGER NULL DEFAULT NULL,
  `published` TINYINT NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'Series'
-- 
-- ---

DROP TABLE IF EXISTS `Series`;
        
CREATE TABLE `Series` (
  `id` INTEGER NOT NULL,
  `leagueId` INTEGER NULL DEFAULT NULL,
  `season` VARCHAR(255) NULL DEFAULT NULL,
  `label` VARCHAR(255) NULL DEFAULT NULL,
  `labelPublic` VARCHAR(255) NULL DEFAULT NULL,
  `url` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'Tournament'
-- 
-- ---

DROP TABLE IF EXISTS `Tournament`;
        
CREATE TABLE `Tournament` (
  `id` INTEGER NOT NULL,
  `leagueId` INTEGER NULL DEFAULT NULL,
  `seriesId` INTEGER NULL DEFAULT NULL,
  `tournamentName` VARCHAR(255) NULL DEFAULT NULL,
  `namePublic` VARCHAR(255) NULL DEFAULT NULL,
  `isFinished` TINYINT NULL DEFAULT NULL,
  `dateBegin` DATETIME NULL DEFAULT NULL,
  `dateEnd` DATETIME NULL DEFAULT NULL,
  `noVods` TINYINT NULL DEFAULT NULL,
  `season` VARCHAR(255) NULL DEFAULT NULL,
  `published` TINYINT NULL DEFAULT NULL,
  `winner` INTEGER NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'LiveStream'
-- 
-- ---

DROP TABLE IF EXISTS `LiveStream`;
        
CREATE TABLE `LiveStream` (
  `leagueId` INTEGER NOT NULL,
  `language` VARCHAR(255) NOT NULL,
  `displayLanguage` VARCHAR(255) NULL DEFAULT NULL,
  `title` VARCHAR(255) NOT NULL,
  `url` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`leagueId`, `language`, `title`)
);

-- ---
-- Table 'TournamentMatch'
-- 
-- ---

DROP TABLE IF EXISTS `TournamentMatch`;
        
CREATE TABLE `TournamentMatch` (
  `id` INTEGER NOT NULL,
  `tournamentId` INTEGER NULL DEFAULT NULL,
  `tournamentRound` INTEGER NULL DEFAULT NULL,
  `url` VARCHAR(255) NULL DEFAULT NULL,
  `dateTime` DATETIME NULL DEFAULT NULL,
  `winnerId` INTEGER NULL DEFAULT NULL,
  `maxGames` INTEGER NULL DEFAULT NULL,
  `isLive` TINYINT NULL DEFAULT NULL,
  `isFinished` TINYINT NULL DEFAULT NULL,
  `redContestantId` INTEGER NULL DEFAULT NULL,
  `blueContestantId` INTEGER NULL DEFAULT NULL,
  `polldaddyId` VARCHAR(255) NULL DEFAULT NULL,
  `label` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'Game'
-- 
-- ---

DROP TABLE IF EXISTS `Game`;
        
CREATE TABLE `Game` (
  `id` INTEGER NOT NULL,
  `winnerId` INTEGER NULL DEFAULT NULL,
  `dateTime` DATETIME NULL DEFAULT NULL,
  `gameNumber` INTEGER NULL DEFAULT NULL,
  `gameLength` INTEGER NULL DEFAULT NULL,
  `matchId` INTEGER NULL DEFAULT NULL,
  `platformId` VARCHAR(255) NULL DEFAULT NULL,
  `platformGameId` INTEGER NULL DEFAULT NULL,
  `noVods` TINYINT NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'Player'
-- 
-- ---

DROP TABLE IF EXISTS `Player`;
        
CREATE TABLE `Player` (
  `id` INTEGER NOT NULL,
  `name` VARCHAR(255) NULL DEFAULT NULL,
  `bio` VARCHAR(255) NULL DEFAULT NULL,
  `firstName` VARCHAR(255) NULL DEFAULT NULL,
  `lastName` VARCHAR(255) NULL DEFAULT NULL,
  `hometown` VARCHAR(255) NULL DEFAULT NULL,
  `facebookUrl` VARCHAR(255) NULL DEFAULT NULL,
  `twitterUrl` VARCHAR(255) NULL DEFAULT NULL,
  `teamId` INTEGER NULL DEFAULT NULL,
  `profileUrl` VARCHAR(255) NULL DEFAULT NULL,
  `role` VARCHAR(255) NULL DEFAULT NULL,
  `roleId` INTEGER NULL DEFAULT NULL,
  `photoUrl` VARCHAR(255) NULL DEFAULT NULL,
  `isStarter` TINYINT NULL DEFAULT NULL,
  `residency` VARCHAR(255) NULL DEFAULT NULL,
  `contractExpiration` DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'Vod'
-- 
-- ---

DROP TABLE IF EXISTS `Vod`;
        
CREATE TABLE `Vod` (
  `id` INTEGER AUTO_INCREMENT NOT NULL,
  `gameId` INTEGER NULL DEFAULT NULL,
  `type` VARCHAR(255) NULL DEFAULT NULL,
  `url` VARCHAR(255) NULL DEFAULT NULL,
  `embedCode` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'Team'
-- 
-- ---

DROP TABLE IF EXISTS `Team`;
        
CREATE TABLE `Team` (
  `id` INTEGER NOT NULL,
  `name` VARCHAR(255) NULL DEFAULT NULL,
  `bio` VARCHAR(255) NULL DEFAULT NULL,
  `noPlayers` TINYINT NULL DEFAULT NULL,
  `logoUrl` VARCHAR(255) NULL DEFAULT NULL,
  `profileUrl` VARCHAR(255) NULL DEFAULT NULL,
  `teamPhotoUrl` VARCHAR(255) NULL DEFAULT NULL,
  `acronym` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

-- ---
-- Table 'PlayerTournament'
-- 
-- ---

DROP TABLE IF EXISTS `PlayerTournament`;
        
CREATE TABLE `PlayerTournament` (
  `playerId` INTEGER NOT NULL,
  `tournamentId` INTEGER NOT NULL,
  `kda` DECIMAL NULL DEFAULT NULL,
  `killParticipation` DECIMAL NULL DEFAULT NULL,
  `gpm` DECIMAL NULL DEFAULT NULL,
  `totalGold` INTEGER NULL DEFAULT NULL,
  `kills` INTEGER NULL DEFAULT NULL,
  `deaths` INTEGER NULL DEFAULT NULL,
  `assists` INTEGER NULL DEFAULT NULL,
  `minionsKilled` INTEGER NULL DEFAULT NULL,
  `secondsPlayed` INTEGER NULL DEFAULT NULL,
  `gamesPlayed` INTEGER NULL DEFAULT NULL,
  PRIMARY KEY (`playerId`, `tournamentId`)
);

-- ---
-- Table 'TeamTournament'
-- 
-- ---

DROP TABLE IF EXISTS `TeamTournament`;
        
CREATE TABLE `TeamTournament` (
  `teamId` INTEGER NOT NULL,
  `tournamentId` INTEGER NOT NULL,
  `kda` DECIMAL NULL DEFAULT NULL,
  `gpm` DECIMAL NULL DEFAULT NULL,
  `totalGold` INTEGER NULL DEFAULT NULL,
  `kills` INTEGER NULL DEFAULT NULL,
  `deaths` INTEGER NULL DEFAULT NULL,
  `assists` INTEGER NULL DEFAULT NULL,
  `minionsKilled` INTEGER NULL DEFAULT NULL,
  `secondsPlayed` INTEGER NULL DEFAULT NULL,
  `gamesPlayed` INTEGER NULL DEFAULT NULL,
  PRIMARY KEY (`teamId`, `tournamentId`)
);

-- ---
-- Table 'PlayerGame'
-- 
-- ---

DROP TABLE IF EXISTS `PlayerGame`;
        
CREATE TABLE `PlayerGame` (
  `playerId` INTEGER NOT NULL,
  `gameId` INTEGER NOT NULL,
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
-- Table 'TeamGame'
-- 
-- ---

DROP TABLE IF EXISTS `TeamGame`;
        
CREATE TABLE `TeamGame` (
  `teamId` INTEGER NOT NULL,
  `gameId` INTEGER NOT NULL,
  `matchVictory` TINYINT NULL DEFAULT NULL,
  `matchDefeat` TINYINT NULL DEFAULT NULL,
  `baronsKilled` INTEGER NULL DEFAULT NULL,
  `dragonsKilled` INTEGER NULL DEFAULT NULL,
  `firstBlood` TINYINT NULL DEFAULT NULL,
  `firstTower` TINYINT NULL DEFAULT NULL,
  `firstInhibitor` TINYINT NULL DEFAULT NULL,
  `towersKilled` INTEGER NULL DEFAULT NULL,
  PRIMARY KEY (`teamId`, `gameId`)
);

-- ---
-- Foreign Keys 
-- ---

ALTER TABLE `Tournament` ADD FOREIGN KEY (leagueId) REFERENCES `League` (`id`);
ALTER TABLE `LiveStream` ADD FOREIGN KEY (leagueId) REFERENCES `League` (`id`);
ALTER TABLE `TournamentMatch` ADD FOREIGN KEY (tournamentId) REFERENCES `Tournament` (`id`);
ALTER TABLE `TournamentMatch` ADD FOREIGN KEY (redContestantId) REFERENCES `Team` (`id`);
ALTER TABLE `TournamentMatch` ADD FOREIGN KEY (blueContestantId) REFERENCES `Team` (`id`);
ALTER TABLE `Game` ADD FOREIGN KEY (matchId) REFERENCES `TournamentMatch` (`id`);
ALTER TABLE `Player` ADD FOREIGN KEY (teamId) REFERENCES `Team` (`id`);
ALTER TABLE `Vod` ADD FOREIGN KEY (gameId) REFERENCES `Game` (`id`);
ALTER TABLE `PlayerTournament` ADD FOREIGN KEY (playerId) REFERENCES `Player` (`id`);
ALTER TABLE `PlayerTournament` ADD FOREIGN KEY (tournamentId) REFERENCES `Tournament` (`id`);
ALTER TABLE `TeamTournament` ADD FOREIGN KEY (teamId) REFERENCES `Team` (`id`);
ALTER TABLE `TeamTournament` ADD FOREIGN KEY (tournamentId) REFERENCES `Tournament` (`id`);
ALTER TABLE `PlayerGame` ADD FOREIGN KEY (playerId) REFERENCES `Player` (`id`);
ALTER TABLE `PlayerGame` ADD FOREIGN KEY (gameId) REFERENCES `Game` (`id`);
ALTER TABLE `TeamGame` ADD FOREIGN KEY (teamId) REFERENCES `Team` (`id`);
ALTER TABLE `TeamGame` ADD FOREIGN KEY (gameId) REFERENCES `Game` (`id`);

-- ---
-- Table Properties
-- ---

ALTER TABLE `League` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `Series` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `Tournament` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `LiveStream` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `TournamentMatch` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `Game` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `Player` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `Vod` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `Team` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `PlayerTournament` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `TeamTournament` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `PlayerGame` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
ALTER TABLE `TeamGame` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

-- ---
-- Initial Data
-- ---
INSERT INTO `League` (`id`) VALUES (-1);
INSERT INTO `Series` (`id`, `leagueId`) VALUES (-1, -1);

-- ---
-- Test Data
-- ---

-- INSERT INTO `League` (`id`,`color`,`leagueImage`,`defaultTournamentId`,`defaultSeriesId`,`shortName`,`url`,`label`,`noVods`,`menuWeight`,`published`) VALUES
-- ('','','','','','','','','','','');
-- INSERT INTO `Series` (`id`,`leagueId`,`season`,`label`,`labelPublic`,`url`) VALUES
-- ('','','','','','');
-- INSERT INTO `Tournament` (`id`,`leagueId`,`seriesId`,`tournamentName`,`namePublic`,`isFinished`,`dateBegin`,`dateEnd`,`noVods`,`season`,`published`,`winner`) VALUES
-- ('','','','','','','','','','','','');
-- INSERT INTO `LiveStream` (`leagueId`,`language`,`displayLanguage`,`title`,`url`) VALUES
-- ('','','','','');
-- INSERT INTO `TournamentMatch` (`id`,`tournamentId`,`tournamentRound`,`url`,`dateTime`,`winnerId`,`maxGames`,`isLive`,`isFinished`,`redContestantId`,`blueContestantId`,`polldaddyId`,`label`) VALUES
-- ('','','','','','','','','','','','','');
-- INSERT INTO `Game` (`id`,`winnerId`,`dateTime`,`gameNumber`,`gameLength`,`matchId`,`platformId`,`platformGameId`,`noVods`) VALUES
-- ('','','','','','','','','');
-- INSERT INTO `Player` (`id`,`name`,`bio`,`firstName`,`lastName`,`hometown`,`facebookUrl`,`twitterUrl`,`teamId`,`profileUrl`,`role`,`roleId`,`photoUrl`,`isStarter`,`residency`,`contractExpiration`) VALUES
-- ('','','','','','','','','','','','','','','','');
-- INSERT INTO `Vod` (`id`,`gameId`,`type`,`url`,`embedCode`) VALUES
-- ('','','','','');
-- INSERT INTO `Team` (`id`,`name`,`bio`,`noPlayers`,`logoUrl`,`profileUrl`,`teamPhotoUrl`,`acronym`) VALUES
-- ('','','','','','','','');
-- INSERT INTO `PlayerTournament` (`playerId`,`tournamentId`,`kda`,`killParticipation`,`gpm`,`totalGold`,`kills`,`deaths`,`assists`,`minionsKilled`,`secondsPlayed`,`gamesPlayed`) VALUES
-- ('','','','','','','','','','','','');
-- INSERT INTO `TeamTournament` (`teamId`,`tournamentId`,`kda`,`gpm`,`totalGold`,`kills`,`deaths`,`assists`,`minionsKilled`,`secondsPlayed`,`gamesPlayed`) VALUES
-- ('','','','','','','','','','','');
-- INSERT INTO `PlayerGame` (`playerId`,`gameId`,`kills`,`deaths`,`assists`,`minionKills`,`doubleKills`,`tripleKills`,`quadraKills`,`pentaKills`) VALUES
-- ('','','','','','','','','','');
-- INSERT INTO `TeamGame` (`teamId`,`gameId`,`matchVictory`,`matchDefeat`,`baronsKilled`,`dragonsKilled`,`firstBlood`,`firstTower`,`firstInhibitor`,`towersKilled`) VALUES
-- ('','','','','','','','','','');

