#!/usr/bin/perl

use CGI::Pretty qw(:standard);

print header;
print start_html "League of Legends Public API";

print h1("League of Legends Public API"), "\n";
print p("This is an experimental API for Fantasy LCS data. Feedback is very welcome, please <a href='http://ryft.co.uk/out.php?target=email'>email</a> me with any suggestions."), "\n";

print h2("Functions"), "\n";
print p("All endpoints are URIs which take one or more GET parameters and return a JSON-formatted string."), "\n";
print p("For example, the request <tt>lol.ryft.co.uk/api/player.json?id=281</tt> returns <tt>[\"281\",\"Tabzz\",\"AD Carry\"]</tt>."), "\n";

my $functions = {
    'team.json' => {
        description => 'Returns the id, name, acronym, and current number of wins and losses of a single team. Useful for finding team IDs and their current success rate.',
        parameters  => [{ name => 'id', desc => 'The Riot ID of the team.' },
                        { name => 'acronym', desc => 'The acronym which represents the team name.' }],
        },
    'player.json' => {
        description => 'Returns the id, name, and most recently-played role for a single player. Useful for finding the ID of a player by name.',
        parameters  => [{ name => 'id', desc => 'The Riot ID of the player.' },
                        { name => 'name', desc => 'The in-game name of the player.' }],
        },
    'playerScore.json' => {
        description => 'Returns the following vector(s) for each selected game: <pre>[playerId, gameId, kills, deaths, assists, minionKills, tripleKills, quadraKills, pentaKills]</pre>Useful for calculating fantasy points for a particular player.',
        parameters  => [{ name => 'gameId', desc => 'The ID of a single game to be output.' },
                        { name => 'playerId', desc => 'The ID of a player. All games for this player will be returned.' }],
        },
    };

sub param_list {
    my $params = shift;
    my @output = map {b($_->{name}).": ".$_->{desc}} @$params;
    return \@output
}

print "<ul>";
foreach my $function_name (keys $functions) {
    my $function = $functions->{$function_name};
    print
            li(h3($function_name)),
            p($function->{description}),
            p("Parameters, in order of precedence:"),
            ul(
                li({-type=>'square'}, param_list $function->{parameters})
        );
}
print "</ul>";

print end_html, "\n";

