CREATE TABLE Players (
    PlayerID INT PRIMARY KEY,
    PlayerName VARCHAR(100),
    TeamName VARCHAR(100),
    Role VARCHAR(50), -- e.g., Batsman, Bowler, All-Rounder, Wicket-Keeper
    DebutYear INT
);

INSERT INTO Players VALUES
(1, 'Virat Kohli', 'India', 'Batsman', 2008),
(2, 'Steve Smith', 'Australia', 'Batsman', 2010),
(3, 'Mitchell Starc', 'Australia', 'Bowler', 2010),
(4, 'MS Dhoni', 'India', 'Wicket-Keeper', 2004),
(5, 'Ben Stokes', 'England', 'All-Rounder', 2011),
(6, 'Rashid Khan', 'Afghanistan', 'Bowler', 2015),
(7, 'David Warner', 'Australia', 'Batsman', 2009),
(8, 'Jasprit Bumrah', 'India', 'Bowler', 2016),
(9, 'Joe Root', 'England', 'Batsman', 2012),
(10, 'Kane Williamson', 'New Zealand', 'Batsman', 2010);

CREATE TABLE Matches (
    MatchID INT PRIMARY KEY,
    MatchDate DATE,
    Location VARCHAR(100),
    Team1 VARCHAR(100),
    Team2 VARCHAR(100),
    Winner VARCHAR(100)
);

INSERT INTO Matches VALUES
(1, '2023-03-01', 'Mumbai', 'India', 'Australia', 'India'),
(2, '2023-03-05', 'Sydney', 'Australia', 'England', 'England'),
(3, '2023-04-10', 'London', 'England', 'India', 'India'),
(4, '2023-05-15', 'Dubai', 'India', 'Afghanistan', 'India'),
(5, '2023-06-20', 'Melbourne', 'Australia', 'New Zealand', 'Australia');

CREATE TABLE Performance (
    MatchID INT,
    PlayerID INT,
    RunsScored INT,
    WicketsTaken INT,
    Catches INT,
    Stumpings INT,
    NotOut BOOLEAN,
    RunOuts INT,
    FOREIGN KEY (MatchID) REFERENCES Matches(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES Players(PlayerID)
);

INSERT INTO Performance VALUES
(1, 1, 82, 0, 1, 0, FALSE, 0),
(1, 4, 5, 0, 0, 1, TRUE, 0),
(1, 8, 10, 3, 0, 0, FALSE, 1),
(2, 9, 120, 0, 2, 0, TRUE, 0),
(2, 3, 15, 4, 0, 0, FALSE, 0),
(3, 1, 45, 0, 1, 0, FALSE, 0),
(3, 4, 22, 0, 0, 2, TRUE, 0),
(3, 10, 85, 0, 0, 0, FALSE, 1),
(4, 6, 35, 5, 0, 0, FALSE, 0),
(4, 1, 90, 0, 1, 0, FALSE, 0),
(5, 7, 75, 0, 0, 0, TRUE, 0),
(5, 3, 18, 3, 1, 0, FALSE, 0);


CREATE TABLE Teams (
    TeamName VARCHAR(100) PRIMARY KEY,
    Coach VARCHAR(100),
    Captain VARCHAR(100)
);

INSERT INTO Teams VALUES
('India', 'Rahul Dravid', 'Rohit Sharma'),
('Australia', 'Andrew McDonald', 'Pat Cummins'),
('England', 'Brendon McCullum', 'Ben Stokes'),
('Afghanistan', 'Jonathan Trott', 'Hashmatullah Shahidi'),
('New Zealand', 'Gary Stead', 'Kane Williamson');

show databases;
use information_schema;
use performance_schema;
use mysql;
use sys;
SELECT a.PlayerName, 
       SUM(b.RunsScored) / COUNT(DISTINCT b.MatchID) AS Batting_Avg
FROM Performance as b
JOIN Players as a 
ON b.PlayerID = a.PlayerID
GROUP BY a.PlayerName
order by Batting_Avg desc
limit 1;

Select a.teamname, (count(b.winner)*100/count(*)) as win_percentage
from matches as b
join teams as a 
on b.winner = a.teamname
group by teamname
order by win_percentage desc
limit 1;

WITH TeamRuns AS (
    SELECT MatchID, SUM(RunsScored) AS TotalRuns
    FROM Performance
    GROUP BY MatchID
), PlayerContribution AS (
    SELECT p.PlayerID, p.PlayerName, per.MatchID,
           per.RunsScored * 100.0 / tr.TotalRuns AS ContributionPercentage
    FROM Performance per
    JOIN TeamRuns tr ON per.MatchID = tr.MatchID
    JOIN Players p ON per.PlayerID = p.PlayerID
)
SELECT PlayerName, MatchID, ContributionPercentage
FROM PlayerContribution
ORDER BY ContributionPercentage DESC
LIMIT 1;

SELECT p.PlayerName,
       STDDEV(per.RunsScored) AS Consistency
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.PlayerName
ORDER BY Consistency ASC
LIMIT 1;


select matchid, sum(runsscored + wicketstaken + catches) as total_impact
from performance
group by matchid
having total_impact >500;

WITH BestPerformance AS (
    SELECT MatchID, 
           PlayerID, 
           RANK() OVER (PARTITION BY MatchID ORDER BY RunsScored DESC, WicketsTaken DESC) AS position
    FROM Performance
)
SELECT p.PlayerName, COUNT(bp.MatchID) AS PlayerOfTheMatchAwards
FROM BestPerformance bp
JOIN Players p ON bp.PlayerID = p.PlayerID
WHERE position = 1
GROUP BY p.PlayerName
ORDER BY PlayerOfTheMatchAwards DESC
LIMIT 1;

select teamname, count(distinct role) as variety
from players
group by teamname
order by variety desc
limit 1;

WITH MatchScores AS (
    SELECT MatchID, 
           SUM(RunsScored) AS TotalRuns
    FROM Performance 
    GROUP BY MatchID
)
SELECT t1.MatchID, ABS(t1.TotalRuns - t2.TotalRuns) AS RunDifference
FROM MatchScores t1
JOIN MatchScores t2 ON t1.MatchID = t2.MatchID
WHERE t1.TotalRuns <> t2.TotalRuns
ORDER BY RunDifference ASC;

WITH PlayerMatches AS (
    SELECT p.PlayerID, p.PlayerName, p.TeamName,per.MatchID, COUNT(DISTINCT per.MatchID) AS MatchesPlayed
    FROM Players p
    JOIN Performance per ON p.PlayerID = per.PlayerID
    GROUP BY p.PlayerID, p.TeamName
),
TeamMatches AS (
    SELECT COUNT(DISTINCT MatchID) AS TotalMatches
    FROM Matches
    GROUP BY MatchID
)
SELECT pm.PlayerName
FROM PlayerMatches pm
JOIN TeamMatches tm ON pm.MatchID = tm.MatchID
WHERE pm.MatchesPlayed = tm.TotalMatches;

WITH TeamScores AS (
    SELECT MatchID, 
           SUM(RunsScored) AS TotalRuns
    FROM Performance 
    GROUP BY MatchID
)
SELECT t1.MatchID, 
       ABS(t1.TotalRuns - t2.TotalRuns) AS RunMargin
FROM TeamScores t1
JOIN TeamScores t2 ON t1.MatchID = t2.MatchID
ORDER BY RunMargin ASC
LIMIT 1;

SELECT p.TeamName, SUM(per.RunsScored) AS TotalRuns
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.TeamName
ORDER BY TotalRuns DESC;

SELECT DISTINCT m.MatchID
FROM Matches m
JOIN Performance per ON m.Winner = (SELECT TeamName FROM Players WHERE PlayerID = per.PlayerID)
WHERE per.WicketsTaken > 2;

select matchid, runsscored, playerid
from performance
order by runsscored desc
limit 5;

select p.playername, sum(per.wicketstaken) as total_wickets
from performance per
join players p 
on per.playerid = p.playerid
where p.role = 'bowler'
group by playername
having total_wickets > 5;

SELECT per.MatchID, SUM(per.Catches) AS TotalCatches
FROM Performance per
JOIN Matches m ON per.MatchID = m.MatchID
JOIN Players p ON per.PlayerID = p.PlayerID
WHERE p.TeamName = m.Winner
GROUP BY per.MatchID;

SELECT p.PlayerName, 
SUM(per.RunsScored * 1.5 + per.WicketsTaken * 25 + per.Catches * 10 + per.Stumpings * 15 + per.RunOuts * 10) AS ImpactScore
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID
GROUP BY p.PlayerName
HAVING COUNT(per.MatchID) >= 3
ORDER BY ImpactScore DESC
LIMIT 1;

WITH MatchScores AS (
    SELECT MatchID, 
           SUM(RunsScored) AS TotalRuns
    FROM Performance 
    GROUP BY MatchID
)
SELECT t1.MatchID, ABS(t1.TotalRuns - t2.TotalRuns) AS RunDifference
FROM MatchScores t1
JOIN MatchScores t2 ON t1.MatchID = t2.MatchID
WHERE t1.TotalRuns <> t2.TotalRuns
ORDER BY RunDifference ASC;

WITH TeamScores AS (
    SELECT MatchID, 
           SUM(RunsScored) AS TotalRuns
    FROM Performance 
    GROUP BY MatchID
)
SELECT t1.MatchID, 
       ABS(t1.TotalRuns - t2.TotalRuns) AS RunMargin
FROM TeamScores t1
JOIN TeamScores t2 ON t1.MatchID = t2.MatchID
ORDER BY RunMargin ASC;

WITH PlayerMatchPerformance AS (
    SELECT per.MatchID, per.PlayerID, per.RunsScored,
           RANK() OVER (PARTITION BY per.MatchID, p.TeamName ORDER BY per.RunsScored DESC) AS position
    FROM Performance per
    JOIN Players p ON per.PlayerID = p.PlayerID
)
SELECT p.PlayerName
FROM PlayerMatchPerformance pmp
JOIN Players p ON pmp.PlayerID = p.PlayerID
GROUP BY p.PlayerName
HAVING COUNT(pmp.MatchID) > (SELECT COUNT(*) FROM Matches) / 2;

WITH PlayerImpact AS (
    SELECT per.PlayerID, 
	SUM(per.RunsScored * 1.5 + per.WicketsTaken * 25 + per.Catches * 10 + per.Stumpings * 15 + per.RunOuts * 10) / COUNT(per.MatchID) AS AvgImpact
    FROM Performance per
    GROUP BY per.PlayerID
    HAVING COUNT(per.MatchID) >= 3
)
SELECT p.PlayerName, pi.AvgImpact, 
       RANK() OVER (ORDER BY pi.AvgImpact DESC) AS position
FROM PlayerImpact pi
JOIN Players p ON pi.PlayerID = p.PlayerID;

SELECT MatchID, SUM(RunsScored) AS TotalRuns,
       RANK() OVER (ORDER BY SUM(RunsScored) DESC) AS position
FROM Performance
GROUP BY MatchID
LIMIT 3;

SELECT per.PlayerID, p.PlayerName, per.MatchID, 
       SUM(RunsScored * 1.5 + WicketsTaken * 25 + Catches * 10 + Stumpings * 15 + RunOuts * 10) 
       OVER (PARTITION BY per.PlayerID ORDER BY per.MatchID) AS CumulativeImpact
FROM Performance per
JOIN Players p ON per.PlayerID = p.PlayerID;