SET SEARCH_PATH TO ticketchema;
DROP VIEW IF EXISTS q1 CASCADE;

DROP VIEW IF EXISTS intermediate_step CASCADE;


DROP VIEW IF EXISTS sales CASCADE;
create view sales as 
select t.ticket_id, seat_id, price, concert_id 
from ticket t join purchase p 
on t.ticket_id = p.ticket_id;

DROP VIEW IF EXISTS venue_sales CASCADE;
create view venue_sales as 
select venue_id, c.concert_id, concert_name, count(*) as seats_sold, sum(price) as total 
from sales s join concert c 
on s.concert_id = c.concert_id 
group by venue_id, c.concert_id;

DROP VIEW IF EXISTS venue_sections CASCADE;
create view venue_sections as 
select section_id, count(*) as total_seats 
from seat 
group by section_id;

DROP VIEW IF EXISTS venue_seats CASCADE;
create view venue_seats as 
select venue_id, sum(total_seats) as total_seats 
from section s join venue_sections v 
on s.section_id = v.section_id 
group by venue_id;

DROP VIEW IF EXISTS results CASCADE;
create view results as 
select v.venue_id, concert_id, concert_name, total as total_sales,(seats_sold*100)/total_seats as seats_sold 
from venue_seats v join venue_sales s 
on v.venue_id = s.venue_id;

create view q1 as
select concert_name, total_sales, seats_sold 
from venue v join results d 
on v.venue_id = d.venue_id;

select * from q1;
