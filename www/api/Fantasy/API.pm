package Fantasy::API;

use Data::Dumper;
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

sub team_score {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    return $dbh->selectrow_arrayref('SELECT * FROM teamGame WHERE gameId = ?', {}, $params->{gameId})
        if ($params->{gameId});

    return $dbh->selectall_arrayref('SELECT * FROM teamGame WHERE teamId = ?', {}, $params->{teamId})
        if ($params->{teamId});
}

sub player_score {
    my ($self, $params) = @_;
    my $dbh = $self->dbh;

    return $dbh->selectrow_arrayref('SELECT * FROM playerGame WHERE gameId = ?', {}, $params->{gameId})
        if ($params->{gameId});

    return $dbh->selectall_arrayref('SELECT * FROM playerGame WHERE playerId = ?', {}, $params->{playerId})
        if ($params->{playerId});
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

