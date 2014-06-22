#!/usr/bin/perl

use Data::Dumper;
use DateTime;
use DBI;
use JSON;
use LWP::UserAgent;
use YAML::XS qw/LoadFile DumpFile/;

use strict;
use warnings;

my $TID_EU = "102";
my $TID_NA = "104";
my @TOURNAMENTS = ($TID_EU, $TID_NA);

my $config_path = 'config.yml';
my $config = LoadFile $config_path;

# Configure the user agent, LolEsports.com is picky
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0');
$ua->timeout(60);
$ua->env_proxy;

my $dbh = DBI->connect('DBI:mysql:fantasy', $config->{database}->{username}, $config->{database}->{password})
    or die "Cannot connect to database:".DBI->errstr;

# get_schedule(date_ymd)
# Fetches the event schedule from lolesports.com,
# starting at midnight on the day provided in 'date_ymd'.
sub get_schedule {
    my $date_ymd = shift;

    # Fetch the JSON-formatted schedule and parse it
    my $request = "http://na.lolesports.com/api/programming.json?parameters[method]=next&parameters[time]=$date_ymd&parameters[expand_matches]=1";
    my $response = $ua->get($request);

    die $response->status_line unless $response->is_success;
    return decode_json $response->decoded_content;
}

sub get_tournament_stats {
    my $id = shift;
    
    # Fetch the JSON-formatted schedule and parse it
    my $request = "http://na.lolesports.com/api/gameStatsFantasy.json?tournamentId=$id";
    my $response = $ua->get($request);

    die $response->status_line unless $response->is_success;
    return decode_json $response->decoded_content;
}

sub format_datetime {
    my $str = shift;
    $str =~ s/T/ /;
    return substr($str, 0, 16) . ":00";
}

sub parse_event_schedule {
    my $programming = shift;
    
    foreach my $block (@$programming) {
        if ($block->{tournamentId} ~~ @TOURNAMENTS) {
            print "Matches for ".substr($block->{dateTime}, 0, 10)." in the ${\$block->{tournamentName}} Week ${\$block->{week}}:\n";

            # Insert tournament record or update if it exists
            my $sth = $dbh->prepare(
                'INSERT INTO tournament (id, name) VALUES (?, ?)
                ON DUPLICATE KEY UPDATE id = ?, name = ?'
            )   or die "Couldn't prepare statement: ".$dbh->errstr;
            $sth->execute(
                $block->{tournamentId},
                $block->{tournamentName},
                $block->{tournamentId},
                $block->{tournamentName}
            )   or die "Couldn't execute statement: ".$sth->errstr;
            
            parse_event_block($block);
        }
    }
}

sub parse_event_block {
    my $block = shift;

    my $matches = $block->{matches};
    foreach my $match (values $matches) {
        print "> ".$match->{matchName}."\n";

        my $teams = $match->{contestants};
        foreach my $team (values $teams) {

            # Insert team record or update wins/losses
            my $sth_team = $dbh->prepare(
                'INSERT INTO team (id, name, acronym, wins, losses)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE id = ?, name = ?, acronym = ?, wins = ?, losses = ?')
                or die "Couldn't prepare statement: ".$dbh->errstr;
            $sth_team->execute(
                $team->{id},
                $team->{name},
                $team->{acronym},
                $team->{wins},
                $team->{losses},
                $team->{id},
                $team->{name},
                $team->{acronym},
                $team->{wins},
                $team->{losses}
            )   or die "Couldn't execute statement: ".$sth_team->errstr;
        }

        # Insert match record or update winner
        my $sth_match = $dbh->prepare(
            'INSERT INTO `match` (id, tournamentId, tournamentRound, blueId, redId, winnerId, name, dateTime)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE winnerId = ?'
        )   or die "Couldn't prepare statement: ".$dbh->errstr;
        
        $sth_match->execute(
            $match->{matchId},
            $match->{tournament}->{id},
            $match->{tournament}->{round},
            $match->{contestants}->{blue}->{id},
            $match->{contestants}->{red}->{id},
            $match->{winnerId} || 0,
            $match->{matchName},
            (format_datetime $match->{dateTime}),
            $match->{winnerId} || 0,
        )   or die "Couldn't execute statement: ".$sth_match->errstr;

        my $games = $match->{gamesInfo};
        foreach my $game (values $games) {
            
            # Insert game record or update winner
            my $sth_game = $dbh->prepare(
                'INSERT INTO game (id, matchId, winnerId)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE winnerId = ?'
            )   or die "Couldn't prepare statement: ".$dbh->errstr;
            $sth_game->execute(
                $game->{id},
                $match->{matchId},
                $game->{winnerId},
                $game->{winnerId}
            )   or die "Couldn't execute statement: ".$sth_game->errstr;
        }
    }
}

sub parse_team_stats {
    my $games = shift;
    
    foreach my $game_name (keys $games) {
        my $game_id = substr $game_name, 4;
        my $game = $games->{$game_name};

        foreach my $attr (keys $game) {
            next unless substr($attr, 0, 4) eq "team";
            my $team_game = $game->{$attr};

            # Test wether or not we've seen this team before
            my $sth_count_team = $dbh->prepare('SELECT COUNT(1) FROM team WHERE id = ?');
            $sth_count_team->execute($team_game->{teamId})
                or die "Coun't execute statement: ".$sth_count_team->errstr;
            my ($count_team) = $sth_count_team->fetchrow_array;
            if ($count_team == 0) {
                print "Team ".$team_game->{teamId}." not found, re-run pre-processing\n";
                next;
            }

            # Test wether or not we've seen this game before
            my $sth_count_game = $dbh->prepare('SELECT COUNT(1) FROM game WHERE id = ?');
            $sth_count_game->execute($game_id)
                or die "Coun't execute statement: ".$sth_count_game->errstr;
            my ($count_game) = $sth_count_game->fetchrow_array;
            if ($count_game == 0) {
                print "Game ".$game_id." not found, re-run pre-processing\n";
                next;
            }

            my $sth = $dbh->prepare(
                'INSERT INTO teamGame
                    (teamId, gameId, baronsKilled, dragonsKilled,
                    firstBlood, firstTower, firstInhibitor, towersKilled)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE teamId = ?'
            )   or die "Couldn't prepare statement: ".$dbh->errstr;
            $sth->execute(
                $team_game->{teamId},
                $game_id,
                $team_game->{baronsKilled},
                $team_game->{dragonsKilled},
                $team_game->{firstBlood},
                $team_game->{firstTower},
                $team_game->{firstInhibitor},
                $team_game->{towersKilled},
                $team_game->{teamId}
            )   or die "Couldn't execute statement: ".$sth->errstr;
        }
    }
}

sub parse_player_stats {
    my $games = shift;
    
    foreach my $game_name (keys $games) {
        my $game_id = substr $game_name, 4;
        my $game = $games->{$game_name};

        foreach my $attr (keys $game) {
            next unless substr($attr, 0, 6) eq "player";
            my $player_game = $game->{$attr};

            my $sth_player = $dbh->prepare(
                'INSERT INTO player (id, name, role) VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE id = ?, name = ?, role = ?'
            ) or die "Couldn't prepare statement: ".$dbh->errstr;
            $sth_player->execute(
                $player_game->{playerId},
                $player_game->{playerName},
                $player_game->{role},
                $player_game->{playerId},
                $player_game->{playerName},
                $player_game->{role}
            ) or die "Couldn't execute statement: ".$sth_player->errstr;

            # Test wether or not we've seen this game before
            my $sth_count_game = $dbh->prepare('SELECT COUNT(1) FROM game WHERE id = ?');
            $sth_count_game->execute($game_id)
                or die "Coun't execute statement: ".$sth_count_game->errstr;
            my ($count_game) = $sth_count_game->fetchrow_array;
            if ($count_game == 0) {
                print "Game ".$game_id." not found, re-run pre-processing\n";
                next;
            }

            my $sth = $dbh->prepare(
                'INSERT INTO playerGame
                    (playerId, gameId, kills, deaths, assists, minionKills,
                    doubleKills, tripleKills, quadraKills, pentaKills)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE playerId = ?'
            )   or die "Couldn't prepare statement: ".$dbh->errstr;
            $sth->execute(
                $player_game->{playerId},
                $game_id,
                $player_game->{kills},
                $player_game->{deaths},
                $player_game->{assists},
                $player_game->{minionKills},
                $player_game->{doubleKills},
                $player_game->{tripleKills},
                $player_game->{quadraKills},
                $player_game->{pentaKills},
                $player_game->{playerId}
            )   or die "Couldn't execute statement: ".$sth->errstr;
        }
    }
}

# Gets the date of the earliest incomplete fetch, or today's date
sub get_next_fetch {
    my $sth = $dbh->prepare('SELECT `dateTime` FROM `match` WHERE winnerId = 0 ORDER BY `dateTime` ASC')
        or die "Couldn't prepare statement: ".$dbh->errstr;
    $sth->execute or die "Couldn't execute statement: ".$sth->errstr;
    
    my $next_fetch = $sth->fetchrow_array;
    return ($next_fetch) ? substr($next_fetch, 0, 10) : DateTime->now->ymd;
}

parse_event_schedule (get_schedule $config->{'next-fetch'});

foreach my $id (@TOURNAMENTS) {
    my $stats = get_tournament_stats $id;
    print "Updating team stats for tournament $id\n";
    parse_team_stats $stats->{teamStats};
    print "Updating player stats for tournament $id\n";
    parse_player_stats $stats->{playerStats};
}

# Save the next fetch date to the config file
$config->{'next-fetch'} = get_next_fetch;
DumpFile $config_path, $config;
print "Set next fetch date to ".$config->{'next-fetch'}."\n";

# Disconnect from the database
$dbh->disconnect;

