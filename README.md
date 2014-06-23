# Fantasy LCS
This repository contains tools to examine the statistics for teams and players in the [League of Legends](http://www.lolesports.com/) regional tournaments. European and North American tournaments are currently supported, and other international tournaments will be included soon&#8482; (work in progress).

A lot of the database structure is dictated by the format of the data returned by the lolesports.com API. A public API will be created in the near future.

### Example Usage
There are only 6 teams in the EU or NA LCS which have won a game after losing the first inhibitor:
``` SQL
mysql> SELECT t.name AS team, COUNT(tg.gameId) AS games
    ->     FROM team t, `match` m, game g, teamGame tg
    ->     WHERE   t.id = tg.teamId
    ->         AND tg.gameId = g.id
    ->         AND g.matchId = m.id
    ->         AND g.winnerId = tg.teamId
    ->         AND tg.firstInhibitor = 0
    ->         AND (m.tournamentId = 102 OR m.tournamentId = 104)
    ->     GROUP BY tg.teamId
    ->     ORDER BY games DESC;
+-------------------+-------+
| team              | games |
+-------------------+-------+
| LMQ               |     3 |
| Fnatic            |     1 |
| Alliance          |     1 |
| Cloud9            |     1 |
| Supa Hot Crew     |     1 |
| Copenhagen Wolves |     1 |
+-------------------+-------+
6 rows in set (0.17 sec)
```

### Licence
These tools are licensed under the MIT licence, see the LICENCE file for details.

### Author
James Nicholls
