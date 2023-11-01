-- Rest bylaw.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3(
    driver_id INTEGER,
    start DATE,
    driving INTERVAL,
    breaks INTERVAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTs ALLINFO  CASCADE;
Create view AllInfo as select c.driver_id, d.shift_id, r.request_id, r.datetime as rDatetime, p.datetime as pDatetime, drop.datetime as dDatetime from dispatch d, request r, ClockedIn c, Dropoff drop, Pickup p
where d.request_id = r.request_id and d.shift_id = c.shift_id and r.request_id = drop.request_id and p.request_id = r.request_id;

DROP VIEW IF EXISTs duration CASCADE;
Create view duration as select driver_id, shift_id, request_id, (ddatetime - pdatetime) as duration, rdatetime from allinfo;

DROP VIEW IF EXISTs totalduration CASCADE;
Create view totalduration as select driver_id, sum(duration) as totalduration, date(rdatetime) from duration group by driver_id, date(rdatetime);

DROP VIEW IF EXISTs TwoSameDay CASCADE;
Create view TwoSameDay as select a1.driver_id, a1.shift_id as a1shift_id, a1.request_id as a1request_id, a1.ddatetime as a1ddatetime, a2.shift_id as a2shift_id, a2.request_id as a2request_id, a2.pdatetime as a2pdatetime,
a2.pdatetime - a1.ddatetime as timebetween from allinfo a1, allinfo a2 where a1.driver_id = a2.driver_id and a1.request_id <> a2.request_id and Date(a1.ddatetime) = Date(a2.pdatetime) and a1.ddatetime < a2.pdatetime;

DROP VIEW IF EXISTs Break CASCADE;
Create view break as select timerecord.driver_id, timerecord.request_id, timerecord.min as break, date(allinfo.rdatetime) from
(select driver_id, a2request_id as request_id, min(timebetween) from twosameday group by driver_id, a2request_id) timerecord, allinfo where timerecord.request_id = allinfo.request_id;

DROP VIEW IF EXISTs longesttotalbreak CASCADE;
Create view longesttotalbreak as select driver_id, max(break) as longestbreak, sum(break) as totalbreak, date from break group by driver_id, date;

DROP VIEW IF EXISTs driverinfo CASCADE;
Create view driverinfo as select * from longesttotalbreak join totalduration using (driver_id, date);

DROP VIEW IF EXISTs cons3days CASCADE;
Create view cons3days as select driver_id, d1.date as start, d1.totalduration + d2.totalduration + d3.totalduration as totalduration, greatest(d1.longestbreak, d2.longestbreak, d3.longestbreak) as longestbreak,
(d1.totalbreak + d2.totalbreak + d3.totalbreak) as totalbreak from driverinfo d1 join driverinfo d2 using (driver_id) join driverinfo d3 using (driver_id) where d1.date + 1 = d2.date and d2.date + 1 = d3.date;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
select driver_id, start, totalduration as driving, totalbreak as breaks from cons3days where totalduration >= '12:00:00' and longestbreak <= '00:15:00';
