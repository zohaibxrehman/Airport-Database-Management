-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS booking_departure CASCADE;
DROP VIEW IF EXISTS passenger_booking CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW booking_departure as
SELECT pass_id, booking.flight_id as flight_id
FROM booking JOIN departure ON booking.flight_id = departure.flight_id;    

CREATE VIEW passenger_booking as 
SELECT passenger.id as pass_id, firstname||' '||surname as name, flight_id
FROM passenger LEFT JOIN booking_departure 
ON passenger.id = booking_departure.pass_id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
SELECT pass_id, name, count(flight_id)
FROM passenger_booking
GROUP BY pass_id, name;
