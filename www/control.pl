#!/usr/bin/perl

use CGI::Pretty qw(:standard);
use CGI::Session;
use Digest::SHA qw(sha256_hex);
use HTML::Entities;
use Time::HiRes qw(time);
use YAML::XS qw(LoadFile);

use strict;
use warnings;

my $query = CGI->new;
my $session = CGI::Session->new
    or die CGI::Session->errstr;
$session->expire('logged_in', '10m');

my $api_config = LoadFile '../api-config.yml';
my $password = $api_config->{control}->{password};

print $session->header;
print start_html "League of Legends API Control Panel";

print h1("League of Legends API Control Panel"), "\n";

sub login_page {
    my $message = shift;
    return p($message) . login_form();
}

sub login_form {
    return start_form
        . 'Password: '
        . password_field('password')
        . submit
        . end_form;
}

sub options_page {
    my $message = shift;
    my $config = LoadFile '../config.yml';
    return p($message . ' Next update due ' . $config->{'next-fetch'} . '.') . options_form();
}

sub options_form {
    return p('Select action: ')
        . start_form
        . radio_group(
            -name   => 'action',
            -values => ['update', 'logout'],
            -linebreak  => 'true',
            -labels => {
                update  =>'Update',
                logout  =>'Disconnect'})
        . submit
        . end_form;
}

if ($session->is_expired) {
    print login_page('Your session has expired.');

} elsif ($session->param('logged_in') == 1 || sha256_hex(param('password')) eq $password) {
    $session->param('logged_in', 1);

    if (param('action') eq 'update') {
        print 'Running update operation... ';
        my $start = time;
        my $output = `cd .. && /usr/bin/perl fetch.pl teams 2>&1`;
        my $end = time;
        printf("completed in %.2fs.\n", $end - $start);
        print options_page(pre(encode_entities $output));

    } elsif (param('action') eq 'logout') {
        $session->param('logged_in', 0);
        print login_page('Successfully logged out.');

    } else {
        print options_page('Welcome!');
    }

} elsif (param('password')) {
    print login_page('Incorrect password.');

} else {
    print login_page('Please log in.');
}

print end_html, "\n";

