-- Frequent riders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q6 CASCADE;

CREATE TABLE q6(
    client_id INTEGER,
    year CHAR(4),
    rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;

DROP VIEW IF EXISTs ALLINFO  CASCADE;
Create view AllInfo as select client_id, request_id, request.datetime, extract(year from request.datetime) as year from client join request using (client_id) join dropoff using (request_id);

DROP VIEW IF EXISTs numtimes  CASCADE;
Create view numtimes as select distinct client_id, count(*) as rides, year from allinfo group by client_id, year;

DROP VIEW IF EXISTs first CASCADE;
Create view first as
select distinct client_id, year, rides from numtimes n1
where n1.rides in ((select max(rides) from numtimes n2 where n2.year = n1.year) Union (select min(rides) from numtimes n2 where n2.year = n1.year));

Drop view if exists exceptfirst cascade;
create view exceptfirst as select * from numtimes except select * from first;

DROP VIEW IF EXISTs second CASCADE;
Create view second as
select distinct client_id, year, rides from exceptfirst n1
where n1.rides in ((select max(rides) from exceptfirst n2 where n2.year = n1.year) Union (select min(rides) from exceptfirst n2 where n2.year = n1.year));

Drop view if exists exceptsecond cascade;
create view exceptsecond as select * from exceptfirst except select * from second;

DROP VIEW IF EXISTs third CASCADE;
Create view third as
select distinct client_id, year, rides from exceptsecond n1
where n1.rides in ((select max(rides) from exceptsecond n2 where n2.year = n1.year) Union (select min(rides) from exceptsecond n2 where n2.year = n1.year));

DROP VIEW IF EXISTS years cascade;
Create view years as select distinct year from allinfo;

DROP VIEW IF EXISTS template cascade;
create view template as select client.client_id, years.year from (select distinct year from allinfo) years cross join client;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6
select client_id, year, case when u.rides is null then 0 else u.rides end from (select * from first union select * from second union select * from third) u right join template using (client_id, year) ;