#!/usr/bin/perl

use Data::Dumper;
use DateTime;
use DBI;
use JSON;
use LWP::UserAgent;
use Readonly;
use YAML::XS qw/LoadFile DumpFile/;

use strict;
use warnings;

Readonly my $CONFIG_PATH => $ENV{'CONFIG_PATH'} || '';

my $config = LoadFile ($CONFIG_PATH . 'config.yml');
my $tournaments = {};

# Configure the user agent, LolEsports.com is picky
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0 (github.com/ryft/FantasyLCS)');
$ua->timeout(60);
$ua->env_proxy;

my $dbh = DBI->connect('DBI:mysql:fantasy', $config->{database}->{username}, $config->{database}->{password})
    or die "Cannot connect to database: ".DBI->errstr;
$dbh->{RaiseError} = 1;

# The Riot API can't be trusted to return matches in order,
# so ensure placeholder IDs are in place to satisfy foreign key constraints
sub touch_tournament {
    my $id = shift;
    my ($count) = $dbh->selectrow_array('SELECT COUNT(1) FROM tournament WHERE id = ?', undef, ($id));
    $dbh->do('INSERT INTO tournament (id) VALUES (?)', {}, $id) unless ($count);
}
sub touch_team {
    my $id = shift;
    my ($count) = $dbh->selectrow_array('SELECT COUNT(1) FROM team WHERE id = ?', undef, ($id));
    $dbh->do('INSERT INTO team (id) VALUES (?)', {}, $id) unless ($count);
}
sub touch_game {
    my $id = shift;
    my ($count) = $dbh->selectrow_array('SELECT COUNT(1) FROM game WHERE id = ?', undef, ($id));
    $dbh->do('INSERT INTO game (id) VALUES (?)', {}, $id) unless ($count);
}

# get_schedule(date_ymd)
# Fetches the event schedule from lolesports.com,
# starting at midnight on the day provided in 'date_ymd'.
sub get_schedule {
    my $date_ymd = shift;

    # Fetch the JSON-formatted schedule and parse it
    my $request = "http://na.lolesports.com/api/programming.json?parameters[method]=next&parameters[time]=$date_ymd&parameters[expand_matches]=1";
    print "Schedule API call: $request\n";
    my $response = $ua->get($request);

    die $response->status_line unless $response->is_success;
    return decode_json $response->decoded_content;
}

sub get_tournament_stats {
    my $id = shift;
    
    # Fetch the JSON-formatted schedule and parse it
    my $request = "http://na.lolesports.com/api/gameStatsFantasy.json?tournamentId=$id";
    print "Stats API call: $request\n";
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
        my $tournament_id   = $block->{tournamentId};
        my $tournament_name = $block->{tournamentName};
        $tournaments->{$tournament_id} = $tournament_name;

        print "Matches for ".substr($block->{dateTime}, 0, 10)." in ${\$block->{label}}:\n";

        # Insert tournament record or update if it exists
        my $sth = $dbh->prepare(
            'INSERT INTO tournament (id, name) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE id = ?, name = ?'
        );
        $sth->execute(
            $tournament_id, $tournament_name,
            $tournament_id, $tournament_name,
        );
        
        parse_event_block($block);
    }
}

sub parse_event_block {
    my $block = shift;

    my $matches = $block->{matches};
    foreach my $match (values $matches) {
        print "> ".$match->{matchName}."\n";

        # Skip team info if teams are TBD
        if ($match->{contestants}) {
            my $teams = $match->{contestants};
            foreach my $team (values $teams) {
                next unless ($team and $team->{id});
    
                # Insert team record or update wins/losses
                my $sth_team = $dbh->prepare(
                    'INSERT INTO team (id, name, acronym, wins, losses)
                    VALUES (?, ?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE id = ?, name = ?, acronym = ?, wins = ?, losses = ?'
                );
                $sth_team->execute(
                    $team->{id}, $team->{name}, $team->{acronym}, $team->{wins}, $team->{losses},
                    $team->{id}, $team->{name}, $team->{acronym}, $team->{wins}, $team->{losses},
                );
            }
        }
        
        # Ensure foreign key constraint is satisfied
        $match->{winnerId} ||= 0;
        touch_team($match->{winnerId});
        touch_tournament($match->{tournament}->{id});

        # Insert match record or update winner
        my $sth_match = $dbh->prepare(
            'INSERT INTO `match` (id, tournamentId, tournamentRound, blueId, redId, winnerId, name, dateTime)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE winnerId = ?'
        );
        $sth_match->execute(
            $match->{matchId},
            $match->{tournament}->{id},
            $match->{tournament}->{round},
            $match->{contestants}->{blue}->{id},
            $match->{contestants}->{red}->{id},
            $match->{winnerId},
            $match->{matchName},
            (format_datetime $match->{dateTime}),
            $match->{winnerId},
        );

        my $games = $match->{gamesInfo};
        foreach my $game (values $games) {
            
            # Insert game record or update winner
            $game->{winnerId} ||= 0;
            touch_team($game->{winnerId});
            my $sth_game = $dbh->prepare(
                'INSERT INTO game (id, matchId, winnerId)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE id = ?, matchId = ?, winnerId = ?'
            );
            $sth_game->execute(
                $game->{id}, $match->{matchId}, $game->{winnerId},
                $game->{id}, $match->{matchId}, $game->{winnerId},
            );
        }
    }
}

sub parse_team_stats {
    my $games = shift;
    
    foreach my $game_name (keys $games) {
        my $game_id = substr $game_name, 4;
        my $game = $games->{$game_name};
        touch_game($game_id);

        foreach my $attr (keys $game) {
            next unless substr($attr, 0, 4) eq "team";
            my $team_game = $game->{$attr};
            touch_team($team_game->{teamId});

            my $sth = $dbh->prepare(
                'INSERT INTO teamGame
                    (teamId, gameId, baronsKilled, dragonsKilled,
                    firstBlood, firstTower, firstInhibitor, towersKilled)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE teamId = ?'
            );
            $sth->execute(
                $team_game->{teamId},
                $game_id,
                $team_game->{baronsKilled},
                $team_game->{dragonsKilled},
                $team_game->{firstBlood},
                $team_game->{firstTower},
                $team_game->{firstInhibitor},
                $team_game->{towersKilled},
                $team_game->{teamId},
            );
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
            );
            $sth_player->execute(
                $player_game->{playerId}, $player_game->{playerName}, $player_game->{role},
                $player_game->{playerId}, $player_game->{playerName}, $player_game->{role},
            );

            # Test wether or not we've seen this game before
            touch_game($game_id);

            my $sth = $dbh->prepare(
                'INSERT INTO playerGame
                    (playerId, gameId, kills, deaths, assists, minionKills,
                    doubleKills, tripleKills, quadraKills, pentaKills)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE playerId = ?'
            );
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
                $player_game->{playerId},
            );
        }
    }
}

# Updates the team associated with a given player ID.
# This method looks at the the teams involved in each max and chooses
# the team with the most occurrences. It's not a very good method and
# gives incorrect results soon after players transfer between teams.
sub update_player_team {
    my $player_id = shift;

    # Fetch all the teams involved in matches where this player has played
    my $teams_involved = $dbh->selectall_arrayref(
        'SELECT m.blueId, m.redId
        FROM `match` m, game g, playerGame pg
        WHERE g.matchId = m.id
          AND pg.gameId = g.id
          AND pg.playerId = ?',
    {}, $player_id);

    # Count the number of appearances each team has made in these matches
    my %team_ids = ();
    foreach my $ids (@$teams_involved) {
        my ($blue_id, $red_id) = @$ids;
        $blue_id and $team_ids{$blue_id}++;
        $red_id and $team_ids{$red_id}++;
    }

    # Find the team with the most appearances (hash key with largest value)
    my ($tid, @keys) = keys   %team_ids;
    my ($max, @vals) = values %team_ids;
    for (0 .. $#keys) {
        if ($vals[$_] > $max) {
            $max = $vals[$_];
            $tid = $keys[$_];
        }
    }

    # Update the player's database record
    $dbh->do('UPDATE player SET teamId = ? WHERE id = ?', {}, $tid, $player_id);
}

# Gets the date of the earliest incomplete fetch, or today's date
sub get_next_fetch {
    my ($next_fetch) = $dbh->selectrow_array('SELECT `dateTime` FROM `match` WHERE winnerId = 0 ORDER BY `dateTime` ASC');
    return ($next_fetch) ? substr($next_fetch, 0, 10) : DateTime->now->ymd;
}

parse_event_schedule (get_schedule $config->{'next-fetch'});

foreach my $id (keys $tournaments) {
    my $stats = get_tournament_stats $id;
    print "Updating team stats for ".$tournaments->{$id}."\n";
    parse_team_stats $stats->{teamStats};
    print "Updating player stats for ".$tournaments->{$id}."\n";
    parse_player_stats $stats->{playerStats};
}

if ($#ARGV > -1 && $ARGV[0] eq 'teams') {
    print "Updating player teams...\n";

    # Get all player (id, name)s to update
    my $players = $dbh->selectall_arrayref('SELECT id FROM player');
    foreach (@$players) {
        update_player_team (shift @$_);
    }
}

# Save the next fetch date to the config file
$config->{'next-fetch'} = get_next_fetch;
DumpFile ($CONFIG_PATH . 'config.yml', $config);
print "Set next fetch date to ".$config->{'next-fetch'}."\n";

# Disconnect from the database
$dbh->disconnect;

