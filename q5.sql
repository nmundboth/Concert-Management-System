-- Bigger and smaller spenders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5(
    client_id INTEGER,
    month VARCHAR(7),
    total FLOAT,
    comparison VARCHAR(30)
);

DROP TABLE IF EXISTS level CASCADE;

CREATE TABLE level(
    comparison VARCHAR(30),
    value BOOLEAN
);

INSERT INTO level(comparison, value) VALUES
    ('below', false),
    ('at or above', true);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
-- Separate clients who had a ride in a distinct month
DROP VIEW IF EXISTS distinct_rides CASCADE;
CREATE VIEW distinct_rides AS
SELECT DISTINCT client_id, request_id, 
CASE WHEN extract('month' from datetime) < 10 THEN
concat(extract('year' from datetime), ' 0', extract('month' from datetime))
ELSE concat(extract('year' from datetime), ' ', extract('month' from datetime)) END AS month
FROM Request;

-- Every combination of client and month
DROP VIEW IF EXISTS client_dates CASCADE;
CREATE VIEW client_dates AS
SELECT DISTINCT client.client_id, month 
FROM distinct_rides, Client;

-- All clients and their months
DROP VIEW IF EXISTS client_rides CASCADE;
CREATE VIEW client_rides AS
SELECT * 
FROM distinct_rides NATURAL FULL JOIN client_dates;

-- Clients who have been billed and not billed
DROP VIEW IF EXISTS total_bills CASCADE;
CREATE VIEW total_bills AS
SELECT * 
FROM client_rides NATURAL LEFT JOIN Billed;

-- Billed clients separated from total_bills
DROP VIEW IF EXISTS billed_clients CASCADE;
CREATE VIEW billed_clients AS
SELECT * 
FROM total_bills
WHERE amount is NOT NULL;

-- Not billed clients separated from total_bills to change null value of amount to 0.
DROP VIEW IF EXISTS not_billed CASCADE;
CREATE VIEW not_billed AS
SELECT request_id, client_id, month, 0 AS amount
FROM total_bills
WHERE amount is NULL;

-- Combining billed and not billed
DROP VIEW IF EXISTS billed_rides CASCADE;
CREATE VIEW billed_rides AS
SELECT * FROM not_billed
UNION
SELECT * FROM billed_clients 
ORDER BY client_id ASC;



--DROP VIEW IF EXISTS billed_rides CASCADE;
--CREATE VIEW billed_rides AS 
--SELECT DISTINCT client_id, request_id, 
--concat(extract('year' from datetime), ' ', extract('month' from datetime)) AS month, amount
--FROM Request NATURAL JOIN Billed NATURAL JOIN Client;

DROP VIEW IF EXISTS total_rides CASCADE;
CREATE VIEW total_rides AS
SELECT client_id, month, sum(amount) AS total
FROM billed_rides 
GROUP BY client_id, month;

-- Individual average --
DROP VIEW IF EXISTS client_month_avg CASCADE;
CREATE VIEW client_month_avg AS
SELECT client_id, month, avg(amount) AS avg_month
FROM billed_rides
GROUP BY client_id, month;

-- Over total average --
DROP VIEW IF EXISTS month_avg CASCADE;
CREATE VIEW month_avg AS
SELECT month, max(avg_month) AS avg_month
FROM client_month_avg
GROUP BY month;

DROP VIEW IF EXISTS total_avg CASCADE;
CREATE VIEW total_avg AS
SELECT client_id, month, total, avg_month 
FROM total_rides NATURAL JOIN month_avg;

--DROP VIEW IF EXISTS temp_ans CASCADE;
--CREATE VIEW temp_ans AS
--SELECT client_id, month, total, compariselect client_id, month, total, max from total_rides natural join month_avg;select client_id, month, total, max from total_rides natural join month_avg;son 
--FROM total_avg JOIN level ON (total >= avg_month) = value;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
SELECT client_id, month, total, comparison
FROM total_avg JOIN level ON (total >= avg_month) = value
ORDER BY client_id ASC;
