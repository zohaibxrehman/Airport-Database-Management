-- Q5. Flight Hopping

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;


CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)

-- HINT: You can answer the question by writing one recursive query below, 
-- without any more views.
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
WITH RECURSIVE hop AS (
(SELECT bpchar('YYZ') AS outbound, 0 AS num_flights,
 (SELECT day + interval '0 hour' from day) as arrival_time)
UNION ALL
(SELECT inbound AS outbound, num_flights + 1, flight.s_arv AS arrival_time
FROM flight NATURAL JOIN hop
WHERE flight.s_dep - hop.arrival_time > interval '0' AND 
flight.s_dep - hop.arrival_time < interval '24:00:00' 
AND num_flights < (SELECT n FROM n))
)
SELECT outbound as destination, num_flights 
FROM hop
WHERE num_flights > 0;
