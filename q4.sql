-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS departed_flights CASCADE;
DROP VIEW IF EXISTS airplane_pcapacity CASCADE;
DROP VIEW IF EXISTS plane_info CASCADE;
DROP VIEW IF EXISTS airplane_tcapacity CASCADE;
DROP VIEW IF EXISTS airplane_live_capacity CASCADE;
DROP VIEW IF EXISTS airplane_verylow_capacity CASCADE;
DROP VIEW IF EXISTS airplane_low_capacity CASCADE;
DROP VIEW IF EXISTS airplane_fair_capacity CASCADE;
DROP VIEW IF EXISTS airplane_normal_capacity CASCADE;
DROP VIEW IF EXISTS airplane_high_capacity CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW departed_flights AS
SELECT booking.flight_id
FROM booking JOIN departure ON booking.flight_id = departure.flight_id;

CREATE VIEW airplane_pcapacity AS
SELECT flight_id, count(flight_id) as count_passengers
FROM departed_flights
GROUP BY flight_id;

CREATE VIEW plane_info AS
SELECT flight_id, airline, plane as tail_number, count_passengers
FROM airplane_pcapacity JOIN flight ON flight_id = id;

CREATE VIEW airplane_tcapacity AS
SELECT tail_number, airline, 
(capacity_economy + capacity_business + capacity_first) as capacity
FROM plane;

CREATE VIEW airplane_live_capacity AS
SELECT airline, tail_number, 
((100 * count_passengers / capacity)) as percent_capacity 
FROM plane_info NATURAL JOIN airplane_tcapacity;

CREATE VIEW airplane_verylow_capacity AS
SELECT A.airline, A.tail_number, count(B.percent_capacity) as very_low
FROM (SELECT airline, tail_number FROM airplane_tcapacity) A 
NATURAL LEFT JOIN (SELECT * FROM airplane_live_capacity
 WHERE percent_capacity >= 0 and percent_capacity < 20) B 
GROUP BY A.airline, A.tail_number; 

CREATE VIEW airplane_low_capacity AS
SELECT A.airline, A.tail_number, count(B.percent_capacity) as low
FROM (SELECT airline, tail_number FROM airplane_tcapacity) A 
NATURAL LEFT JOIN (SELECT * FROM airplane_live_capacity 
WHERE percent_capacity >= 20 and percent_capacity < 40) B 
GROUP BY A.airline, A.tail_number; 

CREATE VIEW airplane_fair_capacity AS
SELECT A.airline, A.tail_number, count(B.percent_capacity) as fair
FROM (SELECT airline, tail_number FROM airplane_tcapacity) A 
NATURAL LEFT JOIN (SELECT * FROM airplane_live_capacity 
WHERE percent_capacity >= 40 and percent_capacity < 60) B
GROUP BY A.airline, A.tail_number; 

CREATE VIEW airplane_normal_capacity AS
SELECT A.airline, A.tail_number, count(B.percent_capacity) as normal
FROM (SELECT airline, tail_number FROM airplane_tcapacity) A
 NATURAL LEFT JOIN (SELECT * FROM airplane_live_capacity 
 WHERE percent_capacity >= 60 and percent_capacity < 80) B 
GROUP BY A.airline, A.tail_number; 

CREATE VIEW airplane_high_capacity AS
SELECT A.airline, A.tail_number, count(B.percent_capacity) as high
FROM (SELECT airline, tail_number FROM airplane_tcapacity) A 
NATURAL LEFT JOIN (SELECT * FROM airplane_live_capacity 
WHERE percent_capacity >= 80) B
GROUP BY A.airline, A.tail_number; 


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
SELECT airline, tail_number, very_low, low, fair, normal, high
FROM (airplane_verylow_capacity NATURAL JOIN airplane_low_capacity NATURAL JOIN 
airplane_fair_capacity NATURAL JOIN airplane_normal_capacity 
NATURAL JOIN airplane_high_capacity);
