-- Ratings histogram.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q7 CASCADE;

CREATE TABLE q7(
    driver_id INTEGER,
    r5 INTEGER,
    r4 INTEGER,
    r3 INTEGER,
    r2 INTEGER,
    r1 INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
-- Finding drivers who had/possibly had a ride
DROP VIEW IF EXISTS dispatch_drivers CASCADE;
CREATE VIEW dispatch_drivers AS
SELECT driver_id, request_id
FROM ClockedIn c JOIN Dispatch d
ON c.shift_id = d.shift_id;

-- Combining drivers who got a rating
DROP VIEW IF EXISTS drivers_list CASCADE;
CREATE VIEW drivers_list AS
SELECT request_id, driver_id, rating
FROM dispatch_drivers NATURAL JOIN DriverRating;

-- Drivers who did not get a rating
DROP VIEW IF EXISTS left_drivers CASCADE;
CREATE VIEW left_drivers AS
SELECT driver_id FROM Driver
EXCEPT
SELECT driver_id FROM drivers_list;

-- Setting ratings to 0 for drivers who did not get a rating
DROP VIEW IF EXISTS no_rating CASCADE;
CREATE VIEW no_rating AS
SELECT driver_id, 0 AS r5, 0 AS r4, 0 AS r3, 0 AS r2, 0 AS r1
FROM left_drivers;

-- Creating columns for every rating: 1, 2, 3, 4, 5
DROP VIEW IF EXISTS count_rating CASCADE;
CREATE VIEW count_rating AS
SELECT DISTINCT driver_id, count(rating) as total, concat('r', rating) as rating
FROM drivers_list
GROUP BY driver_id, rating;

-- Rating columns
DROP VIEW IF EXISTS r1 CASCADE;
CREATE VIEW r1 AS
SELECT driver_id, total as r1
FROM count_rating
WHERE rating = 'r1';

DROP VIEW IF EXISTS r2 CASCADE;
CREATE VIEW r2 AS
SELECT driver_id, total as r2
FROM count_rating
WHERE rating = 'r2';

DROP VIEW IF EXISTS r3 CASCADE;
CREATE VIEW r3 AS
SELECT driver_id, total as r3
FROM count_rating
WHERE rating = 'r3';

DROP VIEW IF EXISTS r4 CASCADE;
CREATE VIEW r4 AS
SELECT driver_id, total as r4
FROM count_rating
WHERE rating = 'r4';

DROP VIEW IF EXISTS r5 CASCADE;
CREATE VIEW r5 AS
SELECT driver_id, total as r5
FROM count_rating
WHERE rating = 'r5';

-- Changing null values to 0 when joining all rating columns
DROP VIEW IF EXISTS with_rating CASCADE;
CREATE VIEW with_rating AS
SELECT driver_id, CASE WHEN r5 IS NULL THEN 0 ELSE r5 END, CASE WHEN r4 IS NULL THEN 0 ELSE r4 END,
	CASE WHEN r3 IS NULL THEN 0 ELSE r3 END, CASE WHEN r2 IS NULL THEN 0 ELSE r2 END, 
	CASE WHEN r1 IS NULL THEN 0 ELSE r1 END
FROM r5 NATURAL FULL JOIN r4 NATURAL FULL JOIN r3 NATURAL FULL JOIN r2 NATURAL FULL JOIN r1;

-- Joining drivers who haven't been rated at all with other drivers
DROP VIEW IF EXISTS driver_rating_count CASCADE;
CREATE VIEW driver_rating_count AS
SELECT * FROM no_rating
UNION
SELECT * FROM with_rating;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q7
SELECT *
FROM driver_rating_count
ORDER BY driver_id ASC;
