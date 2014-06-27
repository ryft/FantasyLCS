package Fantasy::API;

use Data::Dumper;
use DateTime;
use DBI;
use Moose;

use strict;
use warnings;

has 'username' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has 'password' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has 'dbh' => (
    is  => 'rw',
    isa => 'Any',
);

sub BUILD {
    my $self = shift;
    $self->dbh(DBI->connect('DBI:mysql:fantasy', $self->username, $self->password))
        or die "Cannot connect to database:".DBI->errstr;
}

sub DEMOLISH {
    my $self = shift;
    $self->dbh->disconnect;
}

sub team {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    my @team = $dbh->selectrow_array('SELECT * FROM team WHERE id = ?', {}, $params->{id});
    @team = $dbh->selectrow_array('SELECT * FROM team WHERE acronym = ?', {}, $params->{acronym})
        unless @team;

    return \@team;
}

sub player {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    my @player = $dbh->selectrow_array('SELECT * FROM player WHERE id = ?', {}, $params->{id});
    @player = $dbh->selectrow_array('SELECT * FROM player WHERE name = ?', {}, $params->{name})
        unless @player;

    return \@player;
}

sub team_game {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    # TODO There MUST be a better way to do this.
    if ($params->{gameId}) {
        if ($params->{start} && $params->{end}) {
            return $dbh->selectall_arrayref('SELECT tg.* FROM `match` m, game g, teamGame tg WHERE tg.gameId = ? AND tg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` > ? AND m.`dateTime` < ?', {}, $params->{gameId}, $params->{start}, $params->{end});
        } elsif ($params->{start}) {
            return $dbh->selectall_arrayref('SELECT tg.* FROM `match` m, game g, teamGame tg WHERE tg.gameId = ? AND tg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` > ?', {}, $params->{gameId}, $params->{start});
        } elsif ($params->{end}) {
            return $dbh->selectall_arrayref('SELECT tg.* FROM `match` m, game g, teamGame tg WHERE tg.gameId = ? AND tg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` < ?', {}, $params->{gameId}, $params->{end});
        } else {
            return $dbh->selectall_arrayref('SELECT tg.* FROM teamGame tg WHERE tg.gameId = ?', {}, $params->{gameId})
        }
    }

    if ($params->{teamId}) {
        if ($params->{start} && $params->{end}) {
            return $dbh->selectall_arrayref('SELECT tg.* FROM `match` m, game g, teamGame tg WHERE tg.teamId = ? AND tg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` > ? AND m.`dateTime` < ?', {}, $params->{teamId}, $params->{start}, $params->{end});
        } elsif ($params->{start}) {
            return $dbh->selectall_arrayref('SELECT tg.* FROM `match` m, game g, teamGame tg WHERE tg.teamId = ? AND tg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` > ?', {}, $params->{teamId}, $params->{start});
        } elsif ($params->{end}) {
            return $dbh->selectall_arrayref('SELECT tg.* FROM `match` m, game g, teamGame tg WHERE tg.teamId = ? AND tg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` < ?', {}, $params->{teamId}, $params->{end});
        } else {
            return $dbh->selectall_arrayref('SELECT tg.* FROM teamGame tg WHERE tg.teamId = ?', {}, $params->{teamId})
        }
    }
}

sub player_game {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    if ($params->{gameId}) {
        if ($params->{start} && $params->{end}) {
            return $dbh->selectall_arrayref('SELECT pg.* FROM `match` m, game g, playerGame pg WHERE pg.gameId = ? AND pg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` > ? AND m.`dateTime` < ?', {}, $params->{gameId}, $params->{start}, $params->{end});
        } elsif ($params->{start}) {
            return $dbh->selectall_arrayref('SELECT pg.* FROM `match` m, game g, playerGame pg WHERE pg.gameId = ? AND pg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` > ?', {}, $params->{gameId}, $params->{start});
        } elsif ($params->{end}) {
            return $dbh->selectall_arrayref('SELECT pg.* FROM `match` m, game g, playerGame pg WHERE pg.gameId = ? AND pg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` < ?', {}, $params->{gameId}, $params->{end});
        } else {
            return $dbh->selectall_arrayref('SELECT pg.* FROM playerGame pg WHERE pg.gameId = ?', {}, $params->{gameId})
        }
    }

    if ($params->{playerId}) {
        if ($params->{start} && $params->{end}) {
            return $dbh->selectall_arrayref('SELECT pg.* FROM `match` m, game g, playerGame pg WHERE pg.playerId = ? AND pg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` > ? AND m.`dateTime` < ?', {}, $params->{playerId}, $params->{start}, $params->{end});
        } elsif ($params->{start}) {
            return $dbh->selectall_arrayref('SELECT pg.* FROM `match` m, game g, playerGame pg WHERE pg.playerId = ? AND pg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` > ?', {}, $params->{playerId}, $params->{start});
        } elsif ($params->{end}) {
            return $dbh->selectall_arrayref('SELECT pg.* FROM `match` m, game g, playerGame pg WHERE pg.playerId = ? AND pg.gameId = g.id AND g.matchId = m.id AND m.`dateTime` < ?', {}, $params->{playerId}, $params->{end});
        } else {
            return $dbh->selectall_arrayref('SELECT pg.* FROM playerGame pg WHERE pg.playerId = ?', {}, $params->{playerId})
        }
    }
}

sub set_week_params {
    my $params = shift;

    my $today   = DateTime->today;
    my $weekday = $today->day_of_week;

    my $subtracted  = ($weekday + 3) % 7;
    my $start       = $today->subtract(days => $subtracted);
    $start = $start->ymd;

    $params->{start}    = "$start";
    $params->{end}      = "";
}

sub team_score {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    # Restrict the games returned to the previous week of games
    set_week_params $params;
    # It makes no sense to return the score obtained for both teams
    $params->{gameId} = "";
    
    my $points = 0;
    my $tgs = $self->team_game($params);
    foreach my $tg (@$tgs) {
        my ($tid, $gid, $bk, $dk, $fb, $ft, $fi, $tk) = @$tg;
        my ($winner) = $dbh->selectrow_array('SELECT winnerId FROM game g WHERE id = ?', {}, $gid);
        $points += 2 if ($winner == $tid);
        $points += 2 * $fb + 1 * $tk + 2 * $bk + 1 * $dk;
    }

    return $points;
}

sub player_score {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    set_week_params $params;
    $params->{gameId} = "";
    
    my $points = 0;
    my $pgs = $self->player_game($params);
    foreach my $pg (@$pgs) {
        my ($pid, $gid, $k, $d, $a, $cs, $dk, $tk, $qk, $pk) = @$pg;
        $points += 2 * $k - 0.5 * $d + 1.5 * $a + 0.01 * $cs + 2 * $tk + 5 * $qk + 10 * $pk;
        $points += 2 if ($k >= 10 || $a >= 10);
    }

    return $points;
}

sub match {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    return $dbh->selectrow_arrayref('SELECT * FROM `match` WHERE id = ?', {}, $params->{id})
        if ($params->{id});

    return $dbh->selectrow_arrayref('SELECT m.* FROM `match` m, game g WHERE g.matchId = m.id and g.id = ?', {}, $params->{gameId})
        if ($params->{gameId});

    if ($params->{start} && $params->{end}) {
        return $dbh->selectall_arrayref('SELECT * FROM `match` m WHERE `dateTime` > ? AND `dateTime` < ?', {}, $params->{start}, $params->{end});
    } elsif ($params->{start}) {
        return $dbh->selectall_arrayref('SELECT * FROM `match` m WHERE `dateTime` > ?', {}, $params->{start});
    } elsif ($params->{end}) {
        return $dbh->selectall_arrayref('SELECT * FROM `match` m WHERE `dateTime` < ?', {}, $params->{end});
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

