#!/usr/bin/perl

use Data::Dumper;
use DateTime;
use DBI;
use JSON;
use LWP::UserAgent;

use strict;
use warnings;

my $dbh = DBI->connect('DBI:mysql:fantasy', 'root', '3') or die "Cannot connect to database:".DBI->errstr;

my $TID_EU = "102";
my $TID_NA = "104";
my @TOURNAMENTS = ($TID_EU, $TID_NA);
my $MAX_EVENTS = 6;

# Set up the schedule request for the current time
my $time_now = DateTime->now;
my $time_now_ymd = $time_now->ymd;

# Configure the user agent, LolEsports.com is picky
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0');
$ua->timeout(10);
$ua->env_proxy;

# geit_schedule(date_ymd, limit)
# Fetches the event schedule from lolesports.com for up to 'limit'
# events, starting at midnight on the day provided in 'date_ymd'.
sub get_schedule {
    my ($date_ymd, $limit) = @_;

    # Fetch the JSON-formatted schedule and parse it
    my $request = "http://na.lolesports.com/api/programming.json?parameters[method]=next&parameters[time]=$date_ymd&parameters[limit]=$limit&parameters[expand_matches]=1";
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

sub parse_event_block {
    my $block = shift;

    my $matches = $block->{matches};
    foreach my $match (values $matches) {
        print "Processing ".$match->{matchName}."\n";

        my $teams = $match->{contestants};
        foreach my $team (values $teams) {

            # Insert team record or update wins/losses
            my $sth_team = $dbh->prepare(
                'INSERT INTO team (id, name, acronym, wins, losses)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE wins = ?, losses = ?')
                or die "Couldn't prepare statement: ".$dbh->errstr;
            $sth_team->execute(
                $team->{id},
                $team->{name},
                $team->{acronym},
                $team->{wins},
                $team->{losses},
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
}

sub parse_player_stats {
    my $games = shift;
}

my $programming = get_schedule $time_now_ymd, $MAX_EVENTS;

foreach my $block (@$programming) {

    # Dates are formatted %Y-%m-%dT%H:%M:%S+%H:%M
    if ((split "T", $block->{dateTime})[0] eq $time_now_ymd) {
        if ($block->{tournamentId} ~~ @TOURNAMENTS) {

            print "Matches for $time_now_ymd in the ${\$block->{tournamentName}} Week ${\$block->{week}}:\n";

            # Insert tournament record or do nothing if it exists
            my $sth = $dbh->prepare(
                'INSERT INTO tournament (id, name)
                VALUES (?, ?)
                ON DUPLICATE KEY UPDATE id = ?'
            )   or die "Couldn't prepare statement: ".$dbh->errstr;
            $sth->execute($block->{tournamentId}, $block->{tournamentName}, $block->{tournamentId})
                or die "Couldn't execute statement: ".$sth->errstr;
            
            parse_event_block $block;
        }
    }
}

foreach my $id (@TOURNAMENTS) {

    my $stats = get_tournament_stats $id;
    parse_team_stats $stats->{teamStats};
    parse_player_stats $stats->{playerStats};
}

$dbh->disconnect;

