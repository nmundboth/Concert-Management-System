-- Scratching backs?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q8 CASCADE;

CREATE TABLE q8(
    client_id INTEGER,
    reciprocals INTEGER,
    difference FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
-- Join client and driver ratings
DROP VIEW IF EXISTS q8_ratings CASCADE;
CREATE VIEW q8_ratings AS
SELECT c.request_id, c.rating AS client, d.rating AS driver
FROM ClientRating c JOIN DriverRating d
ON c.request_id = d.request_id;

-- Find ride where rating was done
DROP VIEW IF EXISTS q8_clientdriver CASCADE;
CREATE VIEW q8_clientdriver AS
SELECT q.request_id, client_id, client, driver
FROM q8_ratings q JOIN Request r
ON q.request_id = r.request_id;

-- Your query that answers the question goes below the "insert into" line:
-- Compute reciprocals and differences for every client who has at least 1 reciprocal rating
INSERT INTO q8
SELECT DISTINCT client_id, count(*) AS reciprocals, avg(driver - client) AS difference
FROM q8_clientdriver
GROUP BY client_id;
