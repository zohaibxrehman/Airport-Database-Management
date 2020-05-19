-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS booking_departure CASCADE;
DROP VIEW IF EXISTS travel_plan CASCADE;
DROP VIEW IF EXISTS travel_route CASCADE;
DROP VIEW IF EXISTS flight_info CASCADE;
DROP VIEW IF EXISTS domestic_flight CASCADE;
DROP VIEW IF EXISTS international_flight CASCADE;
DROP VIEW IF EXISTS domestic_travel CASCADE;
DROP VIEW IF EXISTS international_travel CASCADE;
DROP VIEW IF EXISTS international_flight CASCADE;
DROP VIEW IF EXISTS domestic_less_delay CASCADE;
DROP VIEW IF EXISTS domestic_more_delay CASCADE;
DROP VIEW IF EXISTS international_less_delay CASCADE;
DROP VIEW IF EXISTS international_more_delay CASCADE;
DROP VIEW IF EXISTS all_delay CASCADE;
DROP VIEW IF EXISTS economy CASCADE;
DROP VIEW IF EXISTS business CASCADE;
DROP VIEW IF EXISTS first CASCADE;
DROP VIEW IF EXISTS class_price CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW economy AS
SELECT flight_id, seat_class, sum(price) AS price
FROM booking
WHERE seat_class = seat_class('economy')
GROUP BY flight_id, seat_class;

CREATE VIEW business AS
SELECT flight_id, seat_class, sum(price) AS price
FROM booking
WHERE seat_class = seat_class('business')
GROUP BY flight_id, seat_class;

CREATE VIEW first AS
SELECT flight_id, seat_class, sum(price) AS price
FROM booking
WHERE seat_class = seat_class('first')
GROUP BY flight_id, seat_class;

CREATE VIEW class_price AS
(SELECT * FROM economy) UNION (SELECT * FROM business) UNION (SELECT * FROM first);

CREATE VIEW booking_departure as
SELECT booking.flight_id as flight_id, class_info.datetime as a_dep, 
booking.seat_class, class_info.price as price
FROM booking JOIN (departure NATURAL JOIN class_price) class_info
 ON booking.flight_id = class_info.flight_id
  AND booking.seat_class = class_info.seat_class; 

CREATE VIEW travel_plan as
SELECT flight_id, a_dep, arrival.datetime as a_arv, seat_class, price 
FROM booking_departure NATURAL JOIN arrival; 

CREATE VIEW travel_route as
SELECT a1.code as outbound, a1.country as d_country, a2.code as inbound, 
a2.country as a_country
FROM airport a1, airport a2;

CREATE VIEW flight_info as 
SELECT id as flight_id, airline as code, d_country, a_country, s_dep, s_arv
FROM travel_route NATURAL JOIN flight; 

CREATE VIEW domestic_flight as
SELECT *
FROM flight_info
WHERE d_country = a_country;

CREATE VIEW international_flight as
SELECT *
FROM flight_info
WHERE d_country != a_country;

CREATE VIEW domestic_travel as
SELECT *
FROM domestic_flight NATURAL JOIN travel_plan;

CREATE VIEW international_travel as
SELECT *
FROM international_flight NATURAL JOIN travel_plan;

CREATE VIEW domestic_less_delay as
SELECT code, extract(year from s_dep) as year, seat_class, 
(0.35 * price) as refund
FROM domestic_travel 
WHERE a_dep - s_dep >= '4:00:00' AND a_dep - s_dep < '10:00:00' 
AND (a_arv - s_arv > (a_dep - s_dep)/2);

CREATE VIEW domestic_more_delay as
SELECT code, extract(year from s_dep) as year, seat_class, 
(0.5 * price) as refund
FROM domestic_travel 
WHERE a_dep - s_dep >= '10:00:00' AND (a_arv - s_arv > (a_dep - s_dep)/2);

CREATE VIEW international_less_delay as 
SELECT code, extract(year from s_dep) as year, seat_class, 
(0.35 * price) as refund
FROM international_travel 
WHERE a_dep - s_dep >= '7:00:00' and a_dep - s_dep < '12:00:00' and 
(a_arv - s_arv > (a_dep - s_dep)/2);

CREATE VIEW international_more_delay as
SELECT code, extract(year from s_dep) as year, seat_class, (0.5 * price) as refund
FROM international_travel 
WHERE a_dep - s_dep >= '12:00:00' and (a_arv - s_arv > (a_dep - s_dep)/2);

CREATE VIEW all_delay as 
(SELECT * FROM domestic_less_delay) UNION (SELECT * FROM domestic_more_delay) 
UNION (SELECT * FROM international_less_delay)
 UNION (SELECT * FROM international_more_delay);


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
SELECT code as airline, name, year, seat_class, refund
FROM all_delay NATURAL JOIN airline;
