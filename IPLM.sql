-- Select * from ball_by_ball
-- Select * from batting_style
-- Select * from bowling_style
-- Select * from city
-- Select * from country
-- Select * from extra_runs
-- Select * from extra_type
-- Select * from matches
-- Select * from out_type
-- Select * from outcome
-- Select * from player
-- Select * from player_match
-- Select * from rolee
-- Select * from season
-- Select * from team
-- Select * from toss_decision 
-- Select * from umpire
-- Select * from venue
-- Select * from wicket_taken
-- Select * from win_by 


-- Objective-1 Solution

SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Ball_by_Ball' AND TABLE_SCHEMA = 'ipl';

-- -- Objective-2 Solution
SELECT SUM(b.Runs_scored + COALESCE(e.Extra_Runs, 0)) AS total 
FROM ball_by_ball b 
LEFT JOIN extra_runs e 
    ON b.Match_Id = e.Match_Id
    AND b.Over_Id = e.Over_Id
    AND b.Ball_ID = e.Ball_Id
    AND b.Innings_No = e.Innings_No
JOIN matches m 
    ON b.Match_Id = m.Match_Id
WHERE b.Team_Batting = 2
and m.Season_Id = 1;

 

-- -- Objective-3 Solution
SELECT count(distinct(p.player_name)) as Above_25
FROM player_match pm 
JOIN player p ON pm.Player_Id = p.Player_Id
JOIN matches m ON pm.Match_Id = m.Match_Id
WHERE YEAR(m.Match_Date) = 2014
AND (2014 - YEAR(p.DOB)) > 25;

-- -- Objective-4 Solution
Select t.Team_Name , count(*)  as Won_Matches
from matches m 
join team t on m.Match_Winner = t.Team_Id
where m.Match_Winner = 2 
and 
year(m.Match_Date) = 2013
group by t.Team_name;

-- -- Objective-5 Solution 

Select p.player_Name,
round(Sum(b.Runs_Scored) * 100.0/count(b.Ball_Id),2) as Strike_Rate
 from ball_by_ball b
join player p 
on b.striker = p.Player_Id
join matches m
on b.Match_Id  = m.Match_Id
where 
year(m.Match_Date) between 2013 and 2016
group by p.player_Name
order by Strike_Rate desc 
limit 10;

-- -- Objective-6 Solution 

SELECT p.Player_Name,
Round((SUM(b.Runs_Scored)/count(distinct(m.Season_Id))),0) as avg_runs
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
JOIN matches m on b.Match_Id = m.Match_Id
GROUP BY p.Player_Name
order by avg_runs desc;


-- -- Objective-7 Solution 
WITH wickets_count_per_player_per_season AS (
    SELECT  
        b.Bowler, 
        m.Season_Id,  
        COUNT(w.Player_Out) AS wickets_taken
    FROM ball_by_ball b
    JOIN wicket_taken w  
        ON b.Match_Id = w.Match_Id 
        AND b.Over_Id = w.Over_Id 
        AND b.Ball_Id = w.Ball_Id 
        AND b.Innings_No = w.Innings_No
    JOIN Matches m  
        ON m.Match_Id = w.Match_Id
    WHERE w.Kind_Out IN (1, 2, 4, 6, 7, 8) 
    GROUP BY b.Bowler, m.Season_Id
),
avg_per_season AS (
    SELECT 
        Bowler, 
        SUM(wickets_taken) * 1.0 / COUNT(DISTINCT Season_Id) AS avg_wicket_per_bowler
    FROM wickets_count_per_player_per_season
    GROUP BY Bowler
)
SELECT 
    p.Player_Name, 
    ROUND(a.avg_wicket_per_bowler, 2) AS Avg_wicket
FROM avg_per_season a
JOIN Player p ON p.Player_Id = a.Bowler
WHERE a.avg_wicket_per_bowler > 0
ORDER BY Avg_wicket DESC;

-- -- Objective-8 Solution 

WITH runs AS (
    SELECT 
        p.Player_ID,
        p.Player_Name,
        COALESCE(SUM(b.Runs_Scored), 0) AS runs
    FROM player p
    INNER JOIN ball_by_ball b 
        ON p.Player_Id = b.Striker
    GROUP BY p.Player_ID, p.Player_Name
),

wickets AS (
    SELECT 
        p.Player_ID,
        p.Player_Name,
        COUNT(w.Player_Out) AS wickets
    FROM wicket_taken w  
    INNER JOIN ball_by_ball b 
        ON w.Ball_Id = b.Ball_Id
        AND w.Over_Id = b.Over_Id
        AND w.Match_Id = b.Match_Id
        AND w.Innings_No = b.Innings_No
    INNER JOIN player p 
        ON b.Bowler = p.Player_Id
    GROUP BY p.Player_ID, p.Player_Name
)

SELECT r.Player_Id, r.Player_Name 
FROM runs r
JOIN wickets w 
    ON r.Player_Id = w.Player_Id
WHERE 
    r.runs > (
        SELECT AVG(total_runs)
        FROM (
            SELECT SUM(Runs_Scored) AS total_runs
            FROM ball_by_ball
            GROUP BY Match_Id
        ) match_avg
    )
AND 
    w.wickets > (
        SELECT AVG(total_wickets)
        FROM (
            SELECT COUNT(Player_Out) AS total_wickets
            FROM wicket_taken
            GROUP BY Match_Id
        ) match_avg
    )
ORDER BY r.Player_Id, r.Player_Name;



-- -- Objective-9 Solution 
DROP TABLE IF EXISTS rcb_record_table;

CREATE TABLE IF NOT EXISTS rcb_record_table AS 
WITH rcb_record AS 
(SELECT m.Venue_Id, v.Venue_Name,
SUM(CASE WHEN Match_Winner = 2 THEN 1 ELSE 0 END) AS Win_record,
SUM(CASE WHEN Match_Winner != 2 THEN 1 ELSE 0 END) AS Loss_record
FROM matches m
JOIN venue v 
ON m.Venue_Id = v.Venue_Id
WHERE (Team_1 = 2 OR Team_2 = 2) AND m.Outcome_type != 2
GROUP BY m.Venue_Id,v.Venue_Name)

SELECT *, Win_record + Loss_record AS Total_Played,
ROUND((Win_record/(Win_record + Loss_record))*100,2) AS Win_percentage, ROUND((Loss_record/(Win_record + Loss_record))*100,2) AS Loss_percentage
FROM rcb_record
ORDER BY Venue_Id;

-- -- Objective-10 Solution 

select bs.Bowling_skill, 
count(w.Player_Out) as wickets 
FROM ball_by_ball b
JOIN wicket_taken w  
ON b.Match_Id = w.Match_Id 
AND b.Over_Id = w.Over_Id 
AND b.Ball_Id = w.Ball_Id 
AND b.Innings_No = w.Innings_No
join player p 
on b.Bowler = p.Player_Id
join bowling_style bs 
on p.Bowling_skill = bs.Bowling_Id
group by bs.Bowling_skill
order by wickets desc;

-- -- Objective-11 Solution 
WITH wickets AS (
    SELECT t.Team_Name,
           s.Season_year,
           COUNT(w.Player_Out) AS Total_wickets
    FROM ball_by_ball b
    JOIN wicket_taken w 
        ON b.Ball_Id = w.Ball_Id
        AND b.Over_Id = w.Over_Id
        AND b.Match_Id = w.Match_Id
    JOIN matches m 
        ON b.Match_Id = m.Match_Id
    JOIN season s 
        ON m.Season_Id = s.Season_Id
    JOIN team t 
        ON b.Team_Bowling = t.Team_Id
    GROUP BY t.Team_Name, s.Season_year
    ORDER BY t.Team_Name, s.Season_year
),

runs AS (
    SELECT t.Team_Name,
           s.Season_year,
           SUM(b.Runs_Scored) AS Runs  -- COUNT is incorrect, SUM should be used to calculate total runs
    FROM ball_by_ball b
    JOIN matches m 
        ON b.Match_Id = m.Match_Id
    JOIN season s 
        ON m.Season_Id = s.Season_Id
    JOIN team t 
        ON b.Team_Batting = t.Team_Id
    GROUP BY t.Team_Name, s.Season_year
    ORDER BY t.Team_Name, s.Season_year
),

Team_data AS (
    SELECT r.Team_Name,
           r.Season_year,
           r.Runs AS runs_scored,
           w.Total_wickets AS wickets_taken,
           LAG(r.Runs) OVER (PARTITION BY r.Team_Name ORDER BY r.Season_year) AS prev_runs,
           LAG(w.Total_wickets) OVER (PARTITION BY w.Team_Name ORDER BY w.Season_year) AS prev_wickets
    FROM runs r 
    JOIN wickets w 
        ON r.Team_Name = w.Team_Name
        AND r.Season_year = w.Season_year
)

SELECT 
    Team_Name,
    Season_year,
    runs_scored,
    wickets_taken,
    prev_runs,
    prev_wickets,
    CASE 
        WHEN runs_scored > prev_runs AND wickets_taken > prev_wickets THEN 'Better'
        WHEN runs_scored < prev_runs AND wickets_taken < prev_wickets THEN 'Worse'
        ELSE 'Same'
    END AS performance_status
FROM Team_data
WHERE prev_runs IS NOT NULL;


-- -- Objective-12 Solution 

-- Powerplay


WITH powerplay_runs AS (
    SELECT 
        m.Season_Id,
        b.Team_Batting,
        SUM(b.Runs_Scored) AS Total_Runs
    FROM ball_by_ball b
    JOIN matches m ON b.Match_Id = m.Match_Id
    WHERE b.Over_Id IN (1, 2, 3, 4)
    GROUP BY m.Season_Id, b.Team_Batting
)

SELECT 
    t.Team_Name,
    pr.Season_Id,
    pr.Total_Runs
FROM powerplay_runs pr
JOIN team t ON pr.Team_Batting = t.Team_Id
ORDER BY pr.Season_Id;

-- Batting_performance

SELECT 
    p.Player_Name,
    SUM(b.Runs_Scored) as Total_Runs,
    ROUND(SUM(b.Runs_Scored) * 100.0 / COUNT(b.Ball_Id), 2) AS Strike_Rate
FROM ball_by_ball b 
JOIN player p ON b.Striker = p.Player_Id
and Striker_Batting_Position between 1 and 8
GROUP BY p.Player_Name
ORDER BY Total_Runs desc , Strike_Rate DESC, p.Player_Name;


-- Bowling

WITH bowling_stats AS (
    SELECT 
        b.Bowler,
        SUM(b.Runs_Scored) AS Runs_Conceded,
        COUNT(*) AS Balls_Bowled
    FROM ball_by_ball b
    GROUP BY b.Bowler
),
wickets_by_bowler AS (
    SELECT 
        b.Bowler,
        COUNT(*) AS Wickets
    FROM ball_by_ball b
    JOIN wicket_taken w 
        ON b.Match_Id = w.Match_Id 
        AND b.Innings_No = w.Innings_No
        AND b.Over_Id = w.Over_Id 
        AND b.Ball_Id = w.Ball_Id
    WHERE w.Player_Out IS NOT NULL
    GROUP BY b.Bowler
)

SELECT 
    p.Player_Name,
    COALESCE(w.Wickets, 0) AS Wickets,
    ROUND(bs.Runs_Conceded * 6.0 / bs.Balls_Bowled, 2) AS Economy
FROM bowling_stats bs
JOIN player p ON bs.Bowler = p.Player_Id
LEFT JOIN wickets_by_bowler w ON bs.Bowler = w.Bowler
ORDER BY Wickets DESC, Economy ASC;

-- -- Objective-13 Solution 

WITH player_wickets AS (
    SELECT v.Venue_Id,v.Venue_Name, 
	p.Player_Name, 
	COUNT(w.Player_Out) AS total_wickets, 
	COUNT(DISTINCT m.Match_Id) AS matches_played 
    FROM wicket_taken w
    JOIN ball_by_ball b 
    ON w.Match_Id = b.Match_Id 
    AND w.Over_Id = b.Over_Id 
    AND w.Ball_Id = b.Ball_Id
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN player p ON p.Player_Id = b.Bowler
    JOIN venue v ON v.Venue_Id = m.Venue_Id
    GROUP BY v.Venue_Id,v.Venue_Name, p.Player_Name
),
avg_wickets AS
(SELECT Venue_Id,Venue_Name, Player_Name, 
       total_wickets, 
       matches_played,
       ROUND(total_wickets / matches_played, 2) AS avg_wickets
FROM player_wickets)
SELECT *, DENSE_RANK() OVER(ORDER BY avg_wickets DESC) AS Ranking
FROM avg_wickets;
-- -- Objective-14 Solution 

WITH ranked_batters AS (
    SELECT 
        p.Player_Name, 
        s.Season_Year,
        SUM(b.Runs_Scored) AS Runs,
        ROW_NUMBER() OVER (PARTITION BY s.Season_Year ORDER BY SUM(b.Runs_Scored) DESC) AS ranked
    FROM ball_by_ball b
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN player p ON b.Striker = p.Player_Id
    GROUP BY p.Player_Name, s.Season_Year
),
batters AS (
    SELECT Player_Name, Season_Year, Runs
    FROM ranked_batters
    WHERE ranked <= 10
),

ranked_bowlers AS (
    SELECT 
        p.Player_Name, 
        s.Season_Year,
        COUNT(w.Player_Out) AS Wickets,
        ROW_NUMBER() OVER (PARTITION BY s.Season_Year ORDER BY COUNT(w.Player_Out) DESC) AS ranked
    FROM ball_by_ball b
    JOIN wicket_taken w 
        ON b.Ball_Id = w.Ball_Id
        AND b.Over_Id = w.Over_Id
        AND b.Match_Id = w.Match_Id
        AND b.Innings_No = w.Innings_No
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN player p ON b.Bowler = p.Player_Id
    GROUP BY p.Player_Name, s.Season_Year
),
bowlers AS (
    SELECT Player_Name, Season_Year, Wickets
    FROM ranked_bowlers
    WHERE ranked <= 10
),

consist AS (
SELECT 
    COALESCE(bt.Player_Name, bw.Player_Name) AS Player_Name,
    COALESCE(bt.Season_Year, bw.Season_Year) AS Season_Year,
    bt.Runs,
    bw.Wickets
FROM batters bt
LEFT JOIN bowlers bw 
    ON bt.Player_Name = bw.Player_Name AND bt.Season_Year = bw.Season_Year

UNION

SELECT 
    COALESCE(bt.Player_Name, bw.Player_Name) AS Player_Name,
    COALESCE(bt.Season_Year, bw.Season_Year) AS Season_Year,
    bt.Runs,
    bw.Wickets
FROM batters bt
RIGHT JOIN bowlers bw 
    ON bt.Player_Name = bw.Player_Name AND bt.Season_Year = bw.Season_Year


)

SELECT 
    DISTINCT(c.Player_Name)
    FROM consist c
WHERE c.Runs > (SELECT AVG(Runs) FROM consist)
   OR c.Wickets > (SELECT AVG(Wickets) FROM consist)
ORDER BY c.Player_Name;


-- -- Objective-15 Solution 

#Batting performance

SELECT p.Player_Name, v.Venue_Name, 
SUM(b.Runs_Scored) AS Total_Runs
FROM ball_by_ball b
JOIN matches m ON m.Match_Id = b.Match_Id
JOIN player p ON p.Player_Id = b.Striker
JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY p.Player_Name, v.Venue_Name
HAVING Total_Runs > 200 
ORDER BY Total_Runs DESC,p.Player_Name;

#Bowling performance
SELECT p.Player_Name, v.Venue_Name, 
COUNT(w.Player_Out) AS Wickets_Taken
FROM ball_by_ball b
JOIN wicket_taken w ON b.Match_Id = w.Match_Id 
AND b.Over_Id = w.Over_Id AND b.Ball_Id = w.Ball_Id AND b.Innings_No = w.Innings_No
JOIN matches m ON m.Match_Id = w.Match_Id
JOIN player p ON p.Player_Id = b.Bowler
JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY p.Player_Name, v.Venue_Name
HAVING Wickets_Taken > 10
ORDER BY  Wickets_Taken DESC,p.Player_Name;

-- SUBJECTIVE QUESTIONS

-- subjective-1- solution

SELECT v.Venue_Id,v.Venue_Name, 
       CASE WHEN m.Toss_Decide = 1 THEN "Field" ELSE "Bat" END AS Toss_Decide, 
       SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END) AS Toss_Winner_Wins, 
       SUM(CASE WHEN m.Toss_Winner != m.Match_Winner THEN 1 ELSE 0 END) AS Toss_Winner_Losses,
       COUNT(m.Match_Id) AS Total_Matches,
       ROUND((SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END) / COUNT(m.Match_Id)) * 100, 2) AS Win_Percentage
FROM matches m
JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY v.Venue_Id,v.Venue_Name, m.Toss_Decide
ORDER BY v.Venue_Id,v.Venue_Name, m.Toss_Decide;


-- subjective-2- solution

WITH ranked_batters AS (
    SELECT 
        p.Player_Name, 
        s.Season_Year,
        SUM(b.Runs_Scored) AS Runs,
        ROW_NUMBER() OVER (PARTITION BY s.Season_Year ORDER BY SUM(b.Runs_Scored) DESC) AS ranked
    FROM ball_by_ball b
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN player p ON b.Striker = p.Player_Id
    GROUP BY p.Player_Name, s.Season_Year
),
batters AS (
    SELECT Player_Name, Season_Year, Runs
    FROM ranked_batters
    WHERE ranked <= 10
),

ranked_bowlers AS (
    SELECT 
        p.Player_Name, 
        s.Season_Year,
        COUNT(w.Player_Out) AS Wickets,
        ROW_NUMBER() OVER (PARTITION BY s.Season_Year ORDER BY COUNT(w.Player_Out) DESC) AS ranked
    FROM ball_by_ball b
    JOIN wicket_taken w 
        ON b.Ball_Id = w.Ball_Id
        AND b.Over_Id = w.Over_Id
        AND b.Match_Id = w.Match_Id
        AND b.Innings_No = w.Innings_No
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN player p ON b.Bowler = p.Player_Id
    GROUP BY p.Player_Name, s.Season_Year
),
bowlers AS (
    SELECT Player_Name, Season_Year, Wickets
    FROM ranked_bowlers
    WHERE ranked <= 10
),

consist AS (
SELECT 
    COALESCE(bt.Player_Name, bw.Player_Name) AS Player_Name,
    COALESCE(bt.Season_Year, bw.Season_Year) AS Season_Year,
    bt.Runs,
    bw.Wickets
FROM batters bt
LEFT JOIN bowlers bw 
    ON bt.Player_Name = bw.Player_Name AND bt.Season_Year = bw.Season_Year

UNION

SELECT 
    COALESCE(bt.Player_Name, bw.Player_Name) AS Player_Name,
    COALESCE(bt.Season_Year, bw.Season_Year) AS Season_Year,
    bt.Runs,
    bw.Wickets
FROM batters bt
RIGHT JOIN bowlers bw 
    ON bt.Player_Name = bw.Player_Name AND bt.Season_Year = bw.Season_Year


)

SELECT 
    DISTINCT(c.Player_Name)
    FROM consist c
WHERE c.Runs > (SELECT AVG(Runs) FROM consist)
   OR c.Wickets > (SELECT AVG(Wickets) FROM consist)
ORDER BY c.Player_Name;

-- subjective-4- solution

WITH batters AS (
    SELECT 
        p.Player_Name, 
        SUM(b.Runs_Scored) AS Runs
    FROM ball_by_ball b
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN player p ON b.Striker = p.Player_Id
    GROUP BY p.Player_Name
	HAVING SUM(b.Runs_Scored) > 200

),

bowlers AS (
    SELECT 
        p.Player_Name, 
        COUNT(w.Player_Out) AS Wickets
    FROM ball_by_ball b
    JOIN wicket_taken w 
        ON b.Ball_Id = w.Ball_Id
        AND b.Over_Id = w.Over_Id
        AND b.Match_Id = w.Match_Id
        AND b.Innings_No = w.Innings_No
    JOIN player p ON b.Bowler = p.Player_Id
    GROUP BY p.Player_Name
	HAVING COUNT(w.Player_Out) > 10
    ORDER BY Wickets desc
    
)

Select bt.Player_Name as All_Rounders,
bt.Runs,
bw.Wickets
 from batters bt 
inner join bowlers bw 
on bt.Player_Name = bw.Player_Name
group by bt.Player_Name 
order by bt.Player_Name,bt.Runs desc,bw.Wickets desc;

-- subjective-5- solution
WITH valued AS (
    SELECT 
        pm.Player_Id,
        p.Player_Name,
        t.Team_Name,
        COUNT(DISTINCT m.Season_Id) AS season_count,
        SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) AS total_wins,
        COUNT(CASE WHEN pm.Player_Id = m.Man_of_the_Match THEN 1 END) AS motm_count,
        DENSE_RANK() OVER (
            PARTITION BY t.Team_Name 
            ORDER BY 
                SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) DESC,
                COUNT(CASE WHEN pm.Player_Id = m.Man_of_the_Match THEN 1 END) DESC
        ) AS ranked
    FROM player_match pm 
    JOIN player p ON pm.Player_Id = p.Player_Id
    JOIN matches m ON m.Match_Id = pm.Match_Id
    JOIN team t ON pm.Team_Id = t.Team_Id
    GROUP BY pm.Player_Id, p.Player_Name, t.Team_Name, pm.Team_Id
)

SELECT 
    Player_Id,
    Player_Name AS Valuable_player,
    Team_Name
FROM valued
WHERE total_wins > 0
  AND ranked = 1
  AND season_count >= 4
ORDER BY total_wins DESC, motm_count DESC;

-- subjective-7- solution

WITH match_runs AS (
    SELECT 
        Match_Id, 
        SUM(Runs_Scored) AS Total_Runs
    FROM ball_by_ball
    GROUP BY Match_Id
)
SELECT 
    v.Venue_Name, 
    Round(AVG(match_runs.Total_Runs),0) AS Avg_Runs_Per_Match,
    COUNT(m.Match_Id) AS Total_Matches
FROM venue v
JOIN matches m ON v.Venue_Id = m.Venue_Id
JOIN match_runs ON m.Match_Id = match_runs.Match_Id
GROUP BY v.Venue_Name
ORDER BY Total_Matches DESC, Avg_Runs_Per_Match DESC
LIMIT 10;

-- subjective-8- solution
Select 
Venue_Name,
Win_record,
Loss_record,
Win_percentage,
Loss_percentage
from rcb_record_table
where Venue_Id = 1;

WITH match_runs AS (
    SELECT 
        Match_Id, 
        SUM(Runs_Scored) AS Total_Runs
    FROM ball_by_ball
    GROUP BY Match_Id
)

SELECT 
    v.Venue_Name, 
    Round(AVG(match_runs.Total_Runs),0) AS Avg_Runs_Per_Match,
    COUNT(m.Match_Id) AS Total_Matches
FROM venue v
JOIN matches m ON v.Venue_Id = m.Venue_Id
JOIN match_runs ON m.Match_Id = match_runs.Match_Id
where v.Venue_Id = 1
GROUP BY v.Venue_Name
ORDER BY Total_Matches DESC, Avg_Runs_Per_Match DESC
LIMIT 10;

-- subjective-9- solution

-- Powerplay

WITH powerplay_runs AS (
    SELECT 
        m.Season_Id,
        b.Team_Batting,
        SUM(b.Runs_Scored) AS Total_Runs
    FROM ball_by_ball b
    JOIN matches m ON b.Match_Id = m.Match_Id
    WHERE b.Over_Id IN (1, 2, 3, 4)
    GROUP BY m.Season_Id, b.Team_Batting
)

SELECT 
    t.Team_Name,
    pr.Season_Id,
    pr.Total_Runs
FROM powerplay_runs pr
JOIN team t ON pr.Team_Batting = t.Team_Id
WHERE t.Team_Id = 2
ORDER BY pr.Season_Id;

-- Batting_performance

SELECT 
    p.Player_Name,
    SUM(b.Runs_Scored) as Total_Runs,
    ROUND(SUM(b.Runs_Scored) * 100.0 / COUNT(b.Ball_Id), 2) AS Strike_Rate
FROM ball_by_ball b 
JOIN player p ON b.Striker = p.Player_Id
where Team_Batting = 2
and Striker_Batting_Position between 1 and 8
GROUP BY p.Player_Name
ORDER BY Total_Runs desc , Strike_Rate DESC, p.Player_Name;

-- Bowling

WITH bowling_stats AS (
    SELECT 
        b.Bowler,
        SUM(b.Runs_Scored) AS Runs_Conceded,
        COUNT(*) AS Balls_Bowled
    FROM ball_by_ball b
    where b.Team_Bowling = 2
    GROUP BY b.Bowler
),
wickets_by_bowler AS (
    SELECT 
        b.Bowler,
        COUNT(*) AS Wickets
    FROM ball_by_ball b
    JOIN wicket_taken w 
        ON b.Match_Id = w.Match_Id 
        AND b.Innings_No = w.Innings_No
        AND b.Over_Id = w.Over_Id 
        AND b.Ball_Id = w.Ball_Id
    WHERE w.Player_Out IS NOT NULL
    GROUP BY b.Bowler
)

SELECT 
    p.Player_Name,
    COALESCE(w.Wickets, 0) AS Wickets,
    ROUND(bs.Runs_Conceded * 6.0 / bs.Balls_Bowled, 2) AS Economy
FROM bowling_stats bs
JOIN player p ON bs.Bowler = p.Player_Id
LEFT JOIN wickets_by_bowler w ON bs.Bowler = w.Bowler
ORDER BY Wickets DESC, Economy ASC;

-- subjective-11- solution

SET SQL_SAFE_UPDATES = 0;

UPDATE team
SET Team_Name = 'Delhi Daredevils'
WHERE Team_Name = 'Delhi Capitals';

SET SQL_SAFE_UPDATES = 1;  -- re-enable it


