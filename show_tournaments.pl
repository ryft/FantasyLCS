#!/usr/bin/perl

use Data::Dumper;
use DateTime::Format::MySQL;
use JSON;
use LWP::UserAgent;
use Readonly;

use strict;
use warnings;

# Configure the user agent, LolEsports.com is picky
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0');
$ua->timeout(60);
$ua->env_proxy;

# get_schedule(date_ymd)
# Fetches the event schedule from lolesports.com,
# starting at midnight on the day provided in 'date_ymd'.
sub get_schedule {
    my $date_ymd = shift;

    # Fetch the JSON-formatted schedule and parse it
    my $request = "http://na.lolesports.com/api/programming.json?parameters[method]=next&parameters[time]=$date_ymd&parameters[expand_matches]=1";
    print "API call: $request\n";
    my $response = $ua->get($request);

    die $response->status_line unless $response->is_success;
    return decode_json $response->decoded_content;
}

sub format_datetime {
    my $str = shift;
    $str =~ s/T/ /;
    return substr($str, 0, 16) . ":00";
}

sub parse_schedule {
    my $programming = shift;
    my $tournaments = {};

    foreach my $block (@$programming) {
        my $tid = $block->{tournamentId};
        next unless defined $tid;

        my $_epoch  = $tournaments->{$tid} || 0;
        my $name    = $block->{tournamentName};
        my $date    = format_datetime($block->{dateTime});
        my $epoch   = DateTime::Format::MySQL->parse_datetime("$date")->epoch;
        $tournaments->{$tid} = {
            id      => $tid,
            name    => $name,
            date    => $date,
            epoch   => $epoch,
        } if ($epoch > $_epoch and $epoch >= time);
    }

    my @sorted = sort {$tournaments->{$a}->{epoch} <=> $tournaments->{$b}->{epoch}} keys %$tournaments;
    foreach (@sorted) {
        print Dumper $tournaments->{$_};
    }
}

parse_schedule( get_schedule '20141115' );

