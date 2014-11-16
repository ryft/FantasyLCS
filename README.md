# Fantasy LCS
This repository contains tools to collect and examine the statistics for teams and players in [League of Legends](http://www.lolesports.com/) tournaments.

### Database
Most of the database structure is dictated by the format of the data returned by the lolesports.com API. The schema is included in `schema.sql`.

### Web API
A web interface to the database is included in the `www` folder. It is currently hosted at [lol.ryft.uk](http://lol.ryft.uk).

### Example Usage
There are 18 teams which have won a game after losing the first inhibitor in any spring playoff tournament:
``` SQL
mysql> SELECT t.name AS team, COUNT(tg.gameId) AS games
    ->     FROM `team` t
    ->         JOIN `teamGame` tg  ON t.id = tg.teamId
    ->         JOIN `game` g       ON g.id = tg.gameId
    ->         JOIN `match` m      ON m.id = g.matchId
    ->         JOIN `tournament` o ON o.id = m.tournamentId
    ->     WHERE   g.winnerId = t.id
    ->         AND tg.firstInhibitor = 0
    ->         AND o.name LIKE '%Spring Split%'
    ->     GROUP BY tg.teamId
    ->     ORDER BY games DESC;
+-----------------------+-------+
| team                  | games |
+-----------------------+-------+
| Fnatic                |    24 |
| Team SoloMid          |    22 |
| Gambit Gaming         |    20 |
| Curse                 |    19 |
| SK Gaming             |    18 |
| Team Dignitas         |    17 |
| Alliance              |    16 |
| Counter Logic Gaming  |    15 |
| Team Coast            |    14 |
| Ninjas in Pyjamas     |    14 |
| XDG                   |    12 |
| Team MRN              |    10 |
| Against All Authority |    10 |
| compLexity White      |     9 |
| Ozone GIANTS          |     8 |
| Dragonborns           |     6 |
| Evil Geniuses         |     1 |
| Cloud9                |     1 |
+-----------------------+-------+
18 rows in set (0.01 sec)
```

### Licence
These tools are licensed under the MIT licence, see the LICENCE file for details.

### Author
James Nicholls
