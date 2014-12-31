#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use DBI;
use JSON;
use List::MoreUtils qw(uniq);
use LWP::UserAgent;
use Readonly;
use YAML::XS qw/LoadFile DumpFile/;

Readonly my $CONFIG_PATH => $ENV{'CONFIG_PATH'} || '';
Readonly my $BASE_URL => 'http://na.lolesports.com/api/';

my $config = LoadFile ($CONFIG_PATH . 'config.yml');
my $db_cfg = $config->{database};
my $tournaments = {};
my $api_calls = 0;

# Configure the user agent, LolEsports.com is picky
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0 (github.com/ryft/FantasyLCS)');
$ua->timeout(60);
$ua->env_proxy;

# Initiate database connection
my $dbh = DBI->connect('DBI:mysql:fantasy', $db_cfg->{username}, $db_cfg->{password})
    or die "Cannot connect to database: ".DBI->errstr;
$dbh->{RaiseError} = 1;

# Fetch a list of leagues and populate the League table
# Returns a series ID -> league ID and tournament ID -> league ID map
sub get_leagues {
    my ($tournament_league_map, $series_league_map) = ({}, {});
    my @league_cols = qw(id color leagueImage defaultTournamentId defaultSeriesId shortName url label noVods menuWeight published);
    my @stream_cols = qw(leagueId language displayLanguage title url);

    my $leagues     = api_call('league.json', {
        'parameters[method]'    => 'all',
        'parameters[published]' => '1,0',
    });

    for my $league (@{ $leagues->{leagues} }) {
        db_insert('League', \@league_cols, $league);
        
        # Update mappings with child series and tournaments
        my $series      = $league->{leagueSeries};
        my $tournaments = $league->{leagueTournaments};
        $series_league_map->{$_}     = $league->{id} for (@$series);
        $tournament_league_map->{$_} = $league->{id} for (@$tournaments);

        # Store live streams in a separate table
        my $nationalities   = $league->{internationalLiveStream};
        for my $nationality (@$nationalities) {
            my $streams     = $nationality->{streams};
            for my $stream  (@$streams) {
                $stream->{leagueId}         = $league->{id};
                $stream->{language}         = $nationality->{language};
                $stream->{displayLanguage}  = $nationality->{display_language};
                db_insert('LiveStream', \@stream_cols, $stream);
            }
        }
    }
    return [$series_league_map, $tournament_league_map];
}

# Fetch a list of series and populate the Series table
# Returns a tournament ID -> series ID map
sub get_series {
    my $series_league_map     = shift;
    my $tournament_series_map = {};

    my @columns = qw(id leagueId season label labelPublic url);
    my $series  = api_call('series.json');

    for my $series_ (@$series) {
        my $id  = $series_->{id};
        my $leagueId    = $series_league_map->{$id};
        $series_->{leagueId} = (defined $leagueId) ? $leagueId : -1;
        db_insert('Series', \@columns, $series_);
        
        my $tournaments = $series_->{tournaments};
        $tournament_series_map->{$_} = $id for (@$tournaments);
    }
    return $tournament_series_map;
}

# Fetch a list of tournaments and populate the Tournament table
# Returns a list of all tournament IDs
sub get_tournaments {
    my ($tournament_league_map, $tournament_series_map) = @_;
    my @tournament_ids = ();

    my @columns = qw(id leagueId seriesId tournamentName namePublic isFinished dateBegin dateEnd noVods season published winner);
    my $tournaments = api_call('tournament.json', {
        'published' => '1,0',
    });

    for my $name (keys %$tournaments) {
        $name =~ m/^tourney(\d+)$/ or next;
        my $tournament = $tournaments->{$name};
        my $id = $1;

        push @tournament_ids, $id;
        $tournament->{id} = $id;
        my ($leagueId, $seriesId) = ($tournament_league_map->{$id}, $tournament_series_map->{$id});
        $tournament->{leagueId} = (defined $leagueId) ? $leagueId : -1;
        $tournament->{seriesId} = (defined $seriesId) ? $seriesId : -1;
        $tournament->{$_} = format_datetime($tournament->{$_}) for (qw(dateBegin dateEnd));
        db_insert('Tournament', \@columns, $tournament);
    }

    @tournament_ids = uniq @tournament_ids;
    return \@tournament_ids;
}

sub get_matches {
    my $tournament_ids = shift;
    my @columns = qw(id tournamentId tournamentRound url dateTime winnerId maxGames isLive isFinished redContestantId blueContestantId polldaddyId label);

    my @all_matches = ();
    my @game_ids    = ();

    for my $tournament_id (@$tournament_ids) {
        my $matches = api_call('schedule.json', {
            'tournamentId'  => $tournament_id,
            'includeLive'   => 'true',
            'includeFuture' => 'true',
            'includeFinished' => 'true',
        });

        for my $match (values %$matches) {
            my $red_id  = $match->{contestants}->{red}->{id};
            my $blue_id = $match->{contestants}->{blue}->{id};

            my $games   = $match->{games};
            push @game_ids, map { $games->{$_}->{id} } (keys %$games);

            $match->{id} = $match->{matchId};
            $match->{dateTime}  = format_datetime($match->{dateTime});
            $match->{tournamentId}  = $tournament_id;
            $match->{tournamentRound}   = $match->{tournament}->{round};
            $match->{redContestantId}   = $red_id;
            $match->{blueContestantId}  = $blue_id;
            db_insert('TournamentMatch', \@columns, $match);
        }
    }
    
    # Return list of games found
    @game_ids = uniq @game_ids;
    return \@game_ids;
}

sub get_teams {
    my $team_ids    = shift;
    my @columns     = qw(id name bio noPlayers logoUrl profileUrl teamPhotoUrl acronym);

    for my $team_id (@$team_ids) {
        my $team = api_call("team/$team_id.json", {
            'teamId'        => $team_id,
            'expandPlayers' => 'true',
        });
        $team->{id} = $team_id;
        db_insert('Team', \@columns, $team);
    }
}

sub get_games {
    my $game_ids    = shift;
    my @game_cols   = qw(id winnerId dateTime gameNumber gameLength matchId platformId platformGameId noVods);
    my @vod_cols    = qw(gameId type url embedCode);

    for my $game_id (@$game_ids) {
        my $game    = api_call("game/$game_id.json", {
            'gameId' => $game_id,
        });
        $game->{id} = $game_id;
        $game->{dateTime} = format_datetime($game->{dateTime});
        db_insert('Game', \@game_cols, $game);

        my $vods    = $game->{vods};
        next unless (ref $vods eq 'HASH');
        for my $vod (values %$vods) {
            $vod->{gameId}  = $game_id;
            $vod->{url}   ||= $vod->{URL};
            db_insert('Vod', \@vod_cols, $vod);
        }
    }
}

sub get_player_ids {
    my $tournament_ids  = shift;
    my @player_ids      = ();

    for my $tournament_id (@$tournament_ids) {
        my $players = api_call('all-player-stats.json', {
            'tournamentId'  => $tournament_id,
        });
        push @player_ids, keys(%$players);
    }

    @player_ids = uniq @player_ids;
    return \@player_ids;
}

sub get_players {
    my $player_ids  = shift;
    my @columns     = qw(id name bio firstName lastName hometown facebookUrl twitterUrl teamId profileUrl role roleId photoUrl isStarter residency contractExpiration);
    my @all_players = ();
    my %team_ids    = ();

    for my $player_id (@$player_ids) {
        my $player = api_call("player/$player_id.json", {
            'playerId' => $player_id,
        });
        $player->{id} = $player_id;
        $player->{contractExpiration} = format_datetime($player->{contractExpiration});
        $player->{teamId} = -1 unless (defined $player->{teamId});
        $team_ids{$player->{teamId}}  = 1;

        # Defer player insertion until after the team is in place
        # so that the foreign key constraint is satisfied
        push @all_players, $player;
    }

    my @teams = keys %team_ids;
    get_teams(\@teams);

    db_insert('Player', \@columns, $_) for (@all_players);

    return \@teams;
}

sub get_team_tournament_stats {
    my $team_ids    = shift;
    my @columns     = qw(teamId tournamentId kda gpm totalGold kills deaths assists minionsKilled secondsPlayed gamesPlayed);

    for my $team_id (@$team_ids) {
        my $team_stats  = api_call('teamStats.json', {
            'teamId'    => $team_id,
        });

        my $tournaments = $team_stats->{tournaments};
        for my $tournament (@$tournaments) {
            my $stats   = $tournament->{stats};

            $stats->{teamId}        = $team_id;
            $stats->{tournamentId}  = $tournament->{tournamentId};
            db_insert('TeamTournament', \@columns, $stats);
        }
    }
}

sub get_player_tournament_stats {
    my $player_ids  = shift;
    my @columns     = qw(playerId tournamentId kda killParticipation gpm totalGold kills deaths assists minionsKilled secondsPlayed gamesPlayed);
    
    for my $player_id (@$player_ids) {
        my $player_stats    = api_call('playerStats.json', {
            'playerId'  => $player_id,
        });

        my $tournaments = $player_stats->{tournaments};
        for my $stats (values %$tournaments) {
            $stats->{playerId}  = $player_id;
            db_insert('PlayerTournament', \@columns, $stats);
        }
    }
}

sub get_fantasy_game_stats {
    my $tournament_ids  = shift;
    my @team_cols   = qw(teamId gameId matchVictory matchDefeat baronsKilled dragonsKilled firstBlood firstTower firstInhibitor towersKilled);
    my @player_cols = qw(playerId gameId kills deaths assists minionKills doubleKills tripleKills quadraKills pentaKills);

    # Make an API call to get the stats for each tournament
    for my $tournament_id (@$tournament_ids) {
        my $fantasy_stats   = api_call('gameStatsFantasy.json', {
            'tournamentId'  => $tournament_id,
        });

        # Parse game stats for each team
        my $team_block  = $fantasy_stats->{teamStats};
        for my $game_name (keys %$team_block) {
            $game_name      =~ m/^game(\d+)$/ or next;
            my $game_id     = $1;
            my $game_stats  = $team_block->{$game_name};

            # Find and store teams involved in this game
            for my $team_name (keys %$game_stats) {
                $team_name      =~ m/^team\d+$/ or next;
                my $team_stats  = $game_stats->{$team_name};
                $team_stats->{gameId}   = $game_id;
                db_insert('TeamGame', \@team_cols, $team_stats);
            }
        }
        
        # Parse game stats for each player
        my $player_block = $fantasy_stats->{playerStats};
        for my $game_name (keys %$player_block) {
            $game_name      =~ m/^game(\d+)$/ or next;
            my $game_id     = $1;
            my $game_stats  = $player_block->{$game_name};

            # Find and store players involved in this game
            for my $player_name (keys %$game_stats) {
                $player_name    =~ m/^player\d+$/ or next;
                my $player_stats = $game_stats->{$player_name};
                $player_stats->{game_id} = $game_id;
                db_insert('PlayerGame', \@player_cols, $player_stats);
            }
        }
    }
}

sub db_insert {
    my ($table, $columns, $object) = @_;
    my $sql = "INSERT INTO $table (" . join(', ', @$columns) . ") "
            . "VALUES (" . join(', ', ('?') x @$columns) . ") "
            . "ON DUPLICATE KEY UPDATE " . join(', ', (map { "$_ = ?" } @$columns));

    my $sth = $dbh->prepare($sql);
    my @values = map { (defined $object->{$_}) ? $object->{$_} : 'NULL' } @$columns;
    print $sql, "\n";
    print join(', ', @values), "\n";
    $sth->execute(@values, @values);
}

sub api_call {
    my ($function, $params) = @_;
    my $req = URI->new($BASE_URL . $function);
    $req->query_form($params);
    print $req->as_string, "\n";
    $api_calls++;

    my $res = $ua->get($req->as_string);
    die $res->status_line unless $res->is_success;
    return decode_json $res->decoded_content;
}

sub format_datetime {
    my $str = shift;
    return unless $str;
    $str =~ s/T/ /;
    return substr($str, 0, 16) . ":00";
}

my $league_maps             = get_leagues;
my ($series_league_map, $tournament_league_map) = @$league_maps;

my $tournament_series_map   = get_series $series_league_map;
my $tournament_ids          = get_tournaments $tournament_league_map, $tournament_series_map;
get_matches $tournament_ids;

my $player_ids = get_player_ids $tournament_ids;
my $team_ids = get_players $player_ids;
get_team_tournament_stats $team_ids;
get_player_tournament_stats $player_ids;
get_fantasy_game_stats $tournament_ids;

# Disconnect from the database
$dbh->disconnect;

