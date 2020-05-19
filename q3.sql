-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS canada CASCADE;
DROP VIEW IF EXISTS usa CASCADE;
DROP VIEW IF EXISTS usa_canada CASCADE;
DROP VIEW IF EXISTS canada_usa CASCADE;
DROP VIEW IF EXISTS all_usa_canada CASCADE;
DROP VIEW IF EXISTS city_pair CASCADE;
DROP VIEW IF EXISTS direct_flight CASCADE;
DROP VIEW IF EXISTS direct_flight_count CASCADE;
DROP VIEW IF EXISTS usa_canada_union CASCADE;
DROP VIEW IF EXISTS usa_canada_anywhere CASCADE;
DROP VIEW IF EXISTS usa_canada_anywhere_direct_flight CASCADE;
DROP VIEW IF EXISTS anywhere_usa_canada CASCADE;
DROP VIEW IF EXISTS anywhere_usa_canada_direct_flight CASCADE;
DROP VIEW IF EXISTS one_connect_pair CASCADE;
DROP VIEW IF EXISTS one_connect CASCADE;
DROP VIEW IF EXISTS one_connect_count CASCADE;
DROP VIEW IF EXISTS usa_canada_anywhere_direct_flight_mod CASCADE;
DROP VIEW IF EXISTS anywhere_anywhere CASCADE;
DROP VIEW IF EXISTS anywhere_anywhere_direct_flight CASCADE;
DROP VIEW IF EXISTS anywhere_usa_canada_direct_flight_mod CASCADE;
DROP VIEW IF EXISTS two_connect_pair CASCADE;
DROP VIEW IF EXISTS two_connect CASCADE;
DROP VIEW IF EXISTS two_connect_count CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW canada AS
SELECT code, city
FROM airport
WHERE country = 'Canada';

CREATE VIEW usa AS
SELECT code, city
FROM airport
WHERE country = 'USA';

CREATE VIEW usa_canada AS
SELECT DISTINCT usa.code as outbound, usa.city as outbound_city, 
canada.code as inbound, canada.city as inbound_city
FROM usa, canada;

CREATE VIEW canada_usa AS
SELECT DISTINCT canada.code as outbound, canada.city as outbound_city,
 usa.code as inbound, usa.city as inbound_city
FROM canada, usa;

CREATE VIEW all_usa_canada AS
(SELECT * FROM usa_canada) UNION (SELECT * FROM canada_usa);

CREATE VIEW city_pair AS
SELECT DISTINCT outbound_city, inbound_city
FROM all_usa_canada;

CREATE VIEW direct_flight AS
SELECT outbound_city, inbound_city, '1' as place_holder, 
march_flight.s_arv AS inbound_arrival
FROM all_usa_canada NATURAL JOIN (SELECT * FROM flight 
WHERE DATE(s_dep) = DATE('2020-04-30') AND 
DATE(s_arv) = DATE('2020-04-30')) march_flight;

CREATE VIEW direct_flight_count AS
SELECT outbound_city, inbound_city, count(place_holder) AS direct, 
min(inbound_arrival) as earliest
FROM city_pair NATURAL LEFT JOIN direct_flight
GROUP BY outbound_city, inbound_city;

-- ONE CONNECTION
CREATE VIEW usa_canada_union AS
(SELECT * FROM canada) UNION (SELECT * FROM usa);

CREATE VIEW usa_canada_anywhere AS
SELECT usa_canada_union.code AS outbound, 
usa_canada_union.city AS outbound_city,
 anywhere.code as inbound, anywhere.city as inbound_city
FROM usa_canada_union, (SELECT code, city FROM airport) anywhere;

CREATE VIEW usa_canada_anywhere_direct_flight AS
SELECT outbound_city, inbound_city AS transit, 
march_flight.s_arv as transit_arrival
FROM usa_canada_anywhere NATURAL JOIN 
(SELECT * FROM flight WHERE DATE(s_dep) = DATE('2020-04-30') AND 
DATE(s_arv) = DATE('2020-04-30')) march_flight;

CREATE VIEW anywhere_usa_canada AS
SELECT usa_canada_union.code as inbound, usa_canada_union.city as inbound_city,
 anywhere.code as outbound, anywhere.city as outbound_city
FROM (SELECT code, city FROM airport) anywhere, usa_canada_union;

CREATE VIEW anywhere_usa_canada_direct_flight AS
SELECT outbound_city AS transit, inbound_city, march_flight.s_dep as 
transit_departure, march_flight.s_arv as inbound_arrival
FROM anywhere_usa_canada NATURAL JOIN (SELECT * FROM flight 
WHERE DATE(s_dep) = DATE('2020-04-30') 
AND DATE(s_arv) = DATE('2020-04-30')) march_flight;

CREATE VIEW one_connect_pair AS
SELECT *
FROM usa_canada_anywhere_direct_flight NATURAL JOIN 
anywhere_usa_canada_direct_flight
WHERE transit_departure - transit_arrival >= '00:30:00' AND 
((outbound_city IN (SELECT city FROM usa) AND 
inbound_city IN (SELECT city FROM canada)) OR
 (outbound_city IN (SELECT city FROM canada) AND 
 inbound_city IN (SELECT city FROM usa)));

CREATE VIEW one_connect AS
SELECT outbound_city, inbound_city, '1' as place_holder, inbound_arrival
FROM one_connect_pair;

CREATE VIEW one_connect_count AS
SELECT outbound_city, inbound_city, count(place_holder) AS one_con, 
min(inbound_arrival) AS earliest
FROM city_pair NATURAL LEFT JOIN one_connect
GROUP BY outbound_city, inbound_city;

-- two connect
CREATE VIEW usa_canada_anywhere_direct_flight_mod AS
SELECT outbound_city, transit AS transit1, transit_arrival as transit1_arrival
FROM usa_canada_anywhere_direct_flight;

CREATE VIEW anywhere_anywhere AS
SELECT anywhere1.code AS outbound, anywhere2.city AS outbound_city, 
anywhere1.code AS inbound, anywhere2.city AS inbound_city
FROM (SELECT code, city FROM airport) anywhere1, 
(SELECT code, city FROM airport) anywhere2;

CREATE VIEW anywhere_anywhere_direct_flight AS
SELECT outbound_city AS transit1, inbound_city AS transit2, 
march_flight.s_dep AS transit1_departure,
 march_flight.s_arv AS transit2_arrival
FROM anywhere_anywhere NATURAL JOIN 
(SELECT * FROM flight 
WHERE DATE(s_dep) = DATE('2020-04-30') 
AND DATE(s_arv) = DATE('2020-04-30')) march_flight; 

CREATE VIEW anywhere_usa_canada_direct_flight_mod AS
SELECT transit AS transit2, inbound_city,
 transit_departure AS transit2_departure,
  inbound_arrival
FROM anywhere_usa_canada_direct_flight;

CREATE VIEW two_connect_pair AS
SELECT *
FROM (usa_canada_anywhere_direct_flight_mod NATURAL JOIN 
anywhere_anywhere_direct_flight) NATURAL JOIN 
anywhere_usa_canada_direct_flight_mod
WHERE transit1_departure - transit1_arrival >= '00:30:00' AND 
transit2_departure - transit2_arrival >= '00:30:00' AND 
((outbound_city IN (SELECT city FROM usa) AND 
inbound_city IN (SELECT city FROM canada)) OR (outbound_city IN
 (SELECT city FROM canada) AND inbound_city IN (SELECT city FROM usa)));

CREATE VIEW two_connect AS
SELECT outbound_city, inbound_city, '1' AS place_holder, inbound_arrival
FROM two_connect_pair;

CREATE VIEW two_connect_count AS
SELECT outbound_city, inbound_city, count(place_holder) AS two_con, 
min(inbound_arrival) AS earliest
FROM city_pair NATURAL LEFT JOIN two_connect
GROUP BY outbound_city, inbound_city;

CREATE VIEW all_count AS
SELECT d.outbound_city AS outbound, d.inbound_city AS inbound, d.direct, 
o.one_con, t.two_con
FROM (direct_flight_count d JOIN one_connect_count o
 ON d.outbound_city = o.outbound_city AND 
 d.inbound_city = o.inbound_city) JOIN two_connect_count t ON
  d.outbound_city = t.outbound_city AND d.inbound_city = t.inbound_city;

CREATE VIEW union_min AS
SELECT a.outbound_city AS outbound, a.inbound_city AS inbound, 
min(a.earliest) AS earliest
FROM ((SELECT outbound_city, inbound_city, earliest FROM direct_flight_count) 
UNION 
(SELECT outbound_city, inbound_city, earliest FROM one_connect_count) UNION 
(SELECT outbound_city, inbound_city, earliest FROM two_connect_count)) a
GROUP BY a.outbound_city, a.inbound_city;
--

-- CREATE VIEW max_helper AS
-- SELECT min(*)
-- FROM (direct_flight_count NATURAL JOIN one_connect_count) NATURAL JOIN two_connect_count
-- GROUP BY outbound_city, inbound_city;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
SELECT outbound, inbound, direct, one_con, two_con, earliest
FROM all_count NATURAL JOIN union_min; 

