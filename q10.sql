-- Rainmakers.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q10 CASCADE;

CREATE TABLE q10(
    driver_id INTEGER,
    month CHAR(2),
    mileage_2020 FLOAT,
    billings_2020 FLOAT,
    mileage_2021 FLOAT,
    billings_2021 FLOAT,
    mileage_increase FLOAT,
    billings_increase FLOAT
);

-- Create a table to include all 12 months
DROP TABLE IF EXISTS months CASCADE;
CREATE TABLE months(
    month INTEGER
);

INSERT INTO months(month) VALUES
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
-- Drivers who had a ride in 2020 and 2021
DROP VIEW IF EXISTS q10_dropoff CASCADE;
CREATE VIEW q10_dropoff AS
SELECT d.request_id, extract('year' from d.datetime) as year, CASE WHEN extract('month' from d.datetime) < 10 
THEN concat('0', extract('month' from d.datetime)) 
ELSE concat('', extract('month' from d.datetime)) END AS month, dis.shift_id
FROM Dropoff d JOIN Dispatch dis
ON d.request_id = dis.request_id
WHERE extract('year' from d.datetime) = 2020 OR extract('year' from d.datetime) = 2021;

-- Billing of those rides
DROP VIEW IF EXISTS q10_billed CASCADE;
CREATE VIEW q10_billed AS
SELECT q.request_id, year, month, shift_id, amount
FROM q10_dropoff q JOIN Billed b
ON q.request_id = b.request_id;

DROP VIEW IF EXISTS q10_billedrides CASCADE;
CREATE VIEW q10_billedrides AS
SELECT driver_id, request_id, year, month, amount
FROM q10_billed b JOIN ClockedIn c
ON b.shift_id = c.shift_id;

-- Adding the mileage of those rides
DROP VIEW IF EXISTS q10_withmileage CASCADE;
CREATE VIEW q10_withmileage AS
SELECT b.request_id, driver_id, year, month, source <@> destination AS mileage, amount
FROM q10_billedrides b JOIN Request r
ON b.request_id = r.request_id;

-- Getting the total mileage and billing in 2020 for every driver-month combination
DROP VIEW IF EXISTS q10_totals2020 CASCADE;
CREATE VIEW q10_totals2020 AS
SELECT DISTINCT driver_id, month, sum(mileage) AS mileage_2020, sum(amount) AS billings_2020
FROM q10_withmileage
WHERE year = 2020
GROUP BY driver_id, month;

-- Getting the total mileage and billing in 2021 for every driver-month combination
DROP VIEW IF EXISTS q10_totals2021 CASCADE;
CREATE VIEW q10_totals2021 AS
SELECT DISTINCT driver_id, month, sum(mileage) AS mileage_2021, sum(amount) AS billings_2021
FROM q10_withmileage
WHERE year = 2021
GROUP BY driver_id, month;

-- Make a combination of every driver and month
DROP VIEW IF EXISTS q10_alldrivermonths CASCADE;
CREATE VIEW q10_alldrivermonths AS
SELECT d.driver_id, CASE WHEN m.month < 10 THEN concat('0', m.month) ELSE concat('', m.month) END AS month
FROM Driver d, months m;

-- Change null values to 0 if there are any when combining q10_totals2020 and q10_totals2021
DROP VIEW IF EXISTS q10_both CASCADE;
CREATE VIEW q10_both AS
SELECT driver_id, month, CASE WHEN mileage_2020 IS NULL THEN 0 ELSE mileage_2020 END, 
CASE WHEN billings_2020 IS NULL THEN 0 ELSE billings_2020 END, 
CASE WHEN mileage_2021 IS NULL THEN 0 ELSE mileage_2021 END, 
CASE WHEN billings_2021 IS NULL THEN 0 ELSE billings_2021 END
FROM q10_totals2020 NATURAL FULL JOIN q10_totals2021;

-- Change null values to 0 if there are any when combining q10_alldrivermonths and q10_both
DROP VIEW IF EXISTS q10_alldrivers CASCADE;
CREATE VIEW q10_alldrivers AS
SELECT driver_id, month, CASE WHEN mileage_2020 IS NULL THEN 0 ELSE mileage_2020 END,
CASE WHEN billings_2020 IS NULL THEN 0 ELSE billings_2020 END,
CASE WHEN mileage_2021 IS NULL THEN 0 ELSE mileage_2021 END,
CASE WHEN billings_2021 IS NULL THEN 0 ELSE billings_2021 END
FROM q10_alldrivermonths NATURAL LEFT JOIN q10_both;

-- Your query that answers the question goes below the "insert into" line:
-- Compute increase in billings and mileage
INSERT INTO q10
SELECT driver_id, month, mileage_2020, billings_2020, mileage_2021, billings_2021, 
mileage_2021 - mileage_2020 AS mileage_increase, billings_2021 - billings_2020 AS billings_increase
FROM q10_alldrivers;
