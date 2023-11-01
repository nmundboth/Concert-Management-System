-- Lure them back.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2(
    client_id INTEGER,
    name VARCHAR(41),
  	email VARCHAR(30),
  	billed FLOAT,
  	decline INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:

DROP VIEW IF EXISTS q2_rides CASCADE;
CREATE VIEW q2_rides AS 
SELECT r.request_id 
FROM Request r JOIN Dropoff d ON r.request_id = d.request_id;

DROP VIEW IF EXISTS q2_condition1 CASCADE;
CREATE VIEW q2_condition1 AS 
SELECT DISTINCT client_id, sum(amount) AS billed 
FROM q2_rides NATURAL JOIN Request NATURAL JOIN Billed 
WHERE Date_part('year', datetime) < 2020 
GROUP BY client_id 
HAVING sum(amount)>=500;

DROP VIEW IF EXISTS q2_condition2 CASCADE;
CREATE VIEW q2_condition2 AS 
SELECT client_id 
FROM q2_condition1 NATURAL JOIN q2_rides NATURAL JOIN Request 
WHERE Date_part('year', datetime) = 2020 
GROUP BY client_id 
HAVING count(*) >=1 AND count(*) <= 10;

DROP VIEW IF EXISTS q2_condition3_2020 CASCADE;
DROP VIEW IF EXISTS q2_condition3_2021 CASCADE;
DROP VIEW IF EXISTS q2_condition3 CASCADE;

CREATE VIEW q2_condition3_2020 AS 
SELECT client_id, request_id AS request_id2020 
FROM Request NATURAL JOIN q2_rides NATURAL JOIN q2_condition2 
WHERE date_part('year', datetime) = 2020;

CREATE VIEW q2_condition3_2021 AS 
SELECT client_id, request_id AS request_id2021 
FROM Request NATURAL JOIN q2_rides NATURAL JOIN q2_condition2 
WHERE date_part('year', datetime) = 2021;

CREATE VIEW q2_condition3 AS 
SELECT client_id, count(request_id2020) - count(request_id2021) AS decline 
FROM q2_condition3_2020 NATURAL FULL JOIN Client NATURAL FULL JOIN q2_condition3_2021 
GROUP BY client_id 
HAVING count(request_id2020) - count(request_id2021) > 0;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
SELECT client_id, firstname || ' ' || surname AS name, email, billed, decline 
FROM q2_condition3 NATURAL JOIN Client NATURAL JOIN q2_condition1;
