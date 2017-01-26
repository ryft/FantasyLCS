#!/usr/bin/perl

use CGI::Pretty qw(:standard);
use YAML::XS qw(LoadFile);

use strict;
use warnings;

my $config = LoadFile '../config.yml';
my $next_fetch = $config->{'next-fetch'};

print header;
print start_html(
    -title  => "League of Legends Public API",
    -head   => [
        Link({
            -rel    => "stylesheet",
            -href   => "https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css",
        }),
        Link({
            -rel    => "stylesheet",
            -href   => "https://bootswatch.com/flatly/bootstrap.min.css",
        }),
        Link({
            -rel    => "stylesheet",
            -href   => "//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css",
        }),
    ],
);

print '<div class="container-fluid">';
print div({style=>'float: right; border: 1px solid black; padding: 6px; margin: 20px; text-align: center;'},
        a({href=>'control.pl'}, 'Control Panel') . br . "Next update: $next_fetch");

print h1("League of Legends Public API"), "\n";

print p("This is an experimental API for <a href='http://fantasy.lolesports.com'>Fantasy LCS</a> data. Feedback is very welcome, please <a href='http://ryft.uk/out.php?target=email'>email</a> me with any suggestions."), "\n";
print p("All the source code involved, including the API, database schema and stats processing, is available on <a href='https://github.com/ryft/FantasyLCS'>Github</a>."), "\n";
print p("Until further notice, all functions are subject to change and/or rate-limiting."), "\n";

print h2("Functions"), "\n";
print p("All endpoints are URIs which take one or more GET parameters and return a JSON-formatted string."), "\n";
print p("For example, the request <tt>lol.ryft.uk/api/player.json?id=281</tt> returns <tt>[\"281\",\"70\",\"Tabzz\",\"AD Carry\"]</tt>."), "\n";
print p("Unless otherwise stated, parameters can't be combined. Lower-bound dates are inclusive, upper bounds exclusive."), "\n";
print p("Dates must be provided in the format YYYY-MM-DD."), "\n";

my $functions = {
    'team.json' => {
        description => 'Returns the id, name, acronym, and current number of wins and losses of a single team. Useful for finding team IDs and their current success rate.',
        parameters  => [{ name => 'id', desc => 'The ID of a team.' },
                        { name => 'acronym', desc => 'The acronym which represents the team name.' }],
    },
    'player.json' => {
        description => 'Returns the id, team id<sup><a id="ref1" href="#fn1">1</a></sup>, name, and most recently-played role for a single player. Useful for finding the ID of a player by name.',
        parameters  => [{ name => 'id', desc => 'The ID of a player.' },
                        { name => 'name', desc => 'The in-game name of a player.' }],
    },
    'teamGame.json' => {
        description => 'Returns the following vector for each selected game: <pre>[teamId, gameId, baronsKilled, dragonsKilled, firstBlood, firstTower, firstInhibitor, towersKilled]</pre>
                        Useful for calculating fantasy points for a particular team.',
        parameters  => [{ name => 'gameId', desc => 'The ID of a game. Both competing teams will be returned.' },
                        { name => 'teamId', desc => 'The ID of a team. All games for the team will be returned.' },
                        { name => 'start / end', desc => 'Bounds on match dates. Must also specify gameId or teamId.' }],
    },
    'playerGame.json' => {
        description => 'Returns the following vector for each selected game: <pre>[playerId, gameId, kills, deaths, assists, minionKills, doubleKills, tripleKills, quadraKills, pentaKills]</pre>
                        Useful for calculating fantasy points for a particular player.',
        parameters  => [{ name => 'gameId', desc => 'The ID of a game. All players involved in the game be returned.' },
                        { name => 'playerId', desc => 'The ID of a player. All games for the player will be returned.' },
                        { name => 'start / end', desc => 'Bounds on match dates. Must also specify gameId or playerId.' }],
    },
    'match.json' => {
        description => 'Returns the following vector for each selected match: <pre>[id, tournamentId, tournamentRound, blueId, redId, winnerId, name, dateTime]</pre>
                        Useful for scoring teams and calculating team fantasy points.',
        parameters  => [{ name => 'id', desc => 'The ID of a single match to be output.' },
                        { name => 'gameId', desc => 'The ID of a game. The match which includes this game ID will be returned.' },
                        { name => 'start', desc => 'Inclusive lower bound on match dates, can be combined with \'end\'.' },
                        { name => 'end', desc => 'Upper bound on match dates, can be combined with \'start\'.' }],
    },
    'playerScore.json' => {
        description => 'Returns the number of fantasy points accrued by the specified player over the past week of LCS games.',
        parameters  => [{ name => 'playerId', desc => 'The ID of a player.' }],
    },
    'teamScore.json' => {
        description => 'Returns the number of fantasy points accrued by the specified team over the past week of LCS games.',
        parameters  => [{ name => 'playerId', desc => 'The ID of a team.' }],
    },
};

sub param_list {
    my $params = shift;
    my @output = map {b($_->{name}).": ".$_->{desc}} @$params;
    return \@output;
}

print '<ul style="list-style-type: square;">';
foreach my $function_name (sort keys $functions) {
    my $function = $functions->{$function_name};
    print
        li({style=>'margin-top: 30px;'}, h4(a({href=>url."api/$function_name", style=>'color: black;'}, "/api/$function_name"))),
        p($function->{description}),
        p("Parameters, in order of precedence:"),
        ul(li({type=>'square'}, param_list $function->{parameters}));
}
print '</ul>';

print h2("Footnotes");
print ol li({id=>'fn1'},
    'The method used for updating teams enumerates all teams involved in matches
    with each individual player, and assigns the player to the team with the most
    occurrences. This deals with team transfers poorly. <a href="#ref1">&#8617;</a>');

print '</div>' . end_html . "\n";

