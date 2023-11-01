-- Consistent raters.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q9 CASCADE;

CREATE TABLE q9(
    client_id INTEGER,
    email VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
-- Rides which were completed and probably include a driver rating
DROP VIEW IF EXISTS q9_ratings CASCADE;
CREATE VIEW q9_ratings AS
SELECT request_id, rating
FROM Dropoff d NATURAL LEFT JOIN DriverRating;

-- Find clients for q9_ratings rides
DROP VIEW IF EXISTS q9_clientrides CASCADE;
CREATE VIEW q9_clientrides AS
SELECT q.request_id, client_id, rating
FROM q9_ratings q JOIN Request r
ON q.request_id = r.request_id;

-- Find drivers who were in those rides
DROP VIEW IF EXISTS q9_dispatchrides CASCADE;
CREATE VIEW q9_dispatchrides AS
SELECT q.request_id, client_id, shift_id, rating
FROM q9_clientrides q JOIN Dispatch d
ON q.request_id = d.request_id;

DROP VIEW IF EXISTS q9_clientdriver CASCADE;
CREATE VIEW q9_clientdriver AS
SELECT q.request_id, client_id, driver_id, rating
FROM q9_dispatchrides q JOIN ClockedIn c
ON q.shift_id = c.shift_id;

-- Count how many ratings and how many rides there were in total for every driver-client combination
DROP VIEW IF EXISTS q9_rideratings CASCADE;
CREATE VIEW q9_rideratings AS
SELECT DISTINCT client_id, driver_id, count(*) AS total_rides, count(rating) AS total_ratings
FROM q9_clientdriver
GROUP BY client_id, driver_id;

-- Exclude clients who did not rate at all
DROP VIEW IF EXISTS q9_everydriverrating CASCADE;
CREATE VIEW q9_everydriverrating AS
SELECT DISTINCT client_id
FROM q9_rideratings
EXCEPT
SELECT DISTINCT client_id
FROM q9_rideratings
WHERE total_ratings = 0;

-- Your query that answers the question goes below the "insert into" line:
-- Client id and email for clients who have rated
INSERT INTO q9
SELECT client_id, email
FROM q9_everydriverrating NATURAL LEFT JOIN Client;
