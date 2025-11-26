
/*
Smart Event Management System - SQL Script
This script creates the database schema, inserts sample data, and contains example queries
covering CRUD operations, joins, aggregates, window functions, subqueries, CASE expressions,
date/time and string functions as required by the project instructions.
Run on MySQL 8.0+.

To use:
1. Save this file and run in your MySQL client:
   SOURCE /path/to/event_management.sql;
   OR paste contents into your client and execute.
*/

-- ========== CREATE DATABASE ==========
DROP DATABASE IF EXISTS event_management;
CREATE DATABASE event_management;
USE event_management;

-- ========== TABLES ==========
-- 1. Events
CREATE TABLE events (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  event_name VARCHAR(255) NOT NULL,
  event_date DATETIME NOT NULL,
  venue_id INT NOT NULL,
  organizer_id INT NOT NULL,
  ticket_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total_seats INT NOT NULL DEFAULT 0,
  available_seats INT NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Venues
CREATE TABLE venues (
  venue_id INT AUTO_INCREMENT PRIMARY KEY,
  venue_name VARCHAR(255) NOT NULL,
  location VARCHAR(255),
  capacity INT NOT NULL DEFAULT 0
);

-- 3. Organizers
CREATE TABLE organizers (
  organizer_id INT AUTO_INCREMENT PRIMARY KEY,
  organizer_name VARCHAR(255) NOT NULL,
  contact_email VARCHAR(255),
  phone_number VARCHAR(50)
);

-- 4. Attendees
CREATE TABLE attendees (
  attendee_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone_number VARCHAR(50)
);

-- 5. Tickets
-- Ensure one attendee can have multiple tickets, but prevent duplicate identical bookings for same event and same attendee.
CREATE TABLE tickets (
  ticket_id INT AUTO_INCREMENT PRIMARY KEY,
  event_id INT NOT NULL,
  attendee_id INT NOT NULL,
  booking_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  status ENUM('Confirmed','Cancelled','Pending') DEFAULT 'Pending',
  UNIQUE KEY uq_event_attendee (event_id, attendee_id),
  FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (attendee_id) REFERENCES attendees(attendee_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 6. Payments
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  ticket_id INT NOT NULL,
  amount_paid DECIMAL(10,2) NOT NULL,
  payment_status ENUM('Success','Failed','Pending') DEFAULT 'Pending',
  payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Optional: simple trigger to keep available_seats in sync when ticket is confirmed/cancelled
DELIMITER $$
CREATE TRIGGER trg_after_ticket_insert
AFTER INSERT ON tickets
FOR EACH ROW
BEGIN
  IF NEW.status = 'Confirmed' THEN
    UPDATE events SET available_seats = available_seats - 1 WHERE event_id = NEW.event_id;
  END IF;
END$$
DELIMITER ;

-- Trigger to handle updates of ticket status (e.g., cancel -> increment available seats)
DELIMITER $$
CREATE TRIGGER trg_after_ticket_update
AFTER UPDATE ON tickets
FOR EACH ROW
BEGIN
  IF OLD.status <> 'Confirmed' AND NEW.status = 'Confirmed' THEN
    UPDATE events SET available_seats = available_seats - 1 WHERE event_id = NEW.event_id;
  ELSEIF OLD.status = 'Confirmed' AND NEW.status <> 'Confirmed' THEN
    UPDATE events SET available_seats = available_seats + 1 WHERE event_id = NEW.event_id;
  END IF;
END$$
DELIMITER ;

-- ========== SAMPLE DATA ==========
-- Venues
INSERT INTO venues (venue_name, location, capacity) VALUES
('Grand Hall A','Mumbai',500),
('Open Grounds','Pune',1000),
('Conference Room 1','Mumbai',120),
('Auditorium X','Bangalore',800);

-- Organizers
INSERT INTO organizers (organizer_name, contact_email, phone_number) VALUES
('Alpha Events','alpha@events.com','+91-9000000001'),
('Beta Creations','contact@beta.com','+91-9000000002'),
('Gamma Organizers',NULL,'+91-9000000003');

-- Events
INSERT INTO events (event_name, event_date, venue_id, organizer_id, ticket_price, total_seats, available_seats) VALUES
('Tech Summit 2025','2025-12-05 10:00:00',1,1,499.00,500,500),
('Music Fest','2025-12-20 18:00:00',2,2,999.00,1000,1000),
('Startup Pitch','2025-11-15 09:30:00',3,1,199.00,120,120),
('Design Workshop','2025-11-10 14:00:00',3,3,299.00,120,120),
('Health Conference','2025-12-01 09:00:00',4,2,399.00,800,800);

-- Attendees
INSERT INTO attendees (name, email, phone_number) VALUES
('Rohit Sharma','rohit@example.com','+91-9810000001'),
('Anita Desai', NULL, '+91-9810000002'),
('Priya Singh','priya@example.com',NULL),
('Vikram Patel','vikram@example.com','+91-9810000004'),
('Nisha Kapoor','nisha@example.com','+91-9810000005');

-- Tickets (some confirmed, some pending)
INSERT INTO tickets (event_id, attendee_id, booking_date, status) VALUES
(1,1,'2025-10-01 12:00:00','Confirmed'),
(1,2,'2025-10-02 13:00:00','Pending'),
(2,3,'2025-10-05 09:00:00','Confirmed'),
(2,4,'2025-10-06 10:00:00','Confirmed'),
(3,1,'2025-10-07 11:00:00','Confirmed'),
(4,5,'2025-10-08 12:00:00','Cancelled');

-- Payments
INSERT INTO payments (ticket_id, amount_paid, payment_status, payment_date) VALUES
(1,499.00,'Success','2025-10-01 12:05:00'),
(3,999.00,'Success','2025-10-05 09:10:00'),
(4,999.00,'Success','2025-10-06 10:15:00'),
(5,199.00,'Pending','2025-10-07 11:20:00'),
(6,299.00,'Failed','2025-10-08 12:30:00');

-- After inserts, adjust available_seats to reflect confirmed tickets (simple recalculation)
-- Updated to avoid MySQL 'safe update mode' errors by using a JOIN on the key column.
UPDATE events e
LEFT JOIN (
    SELECT event_id, COUNT(*) AS confirmed_count
    FROM tickets
    WHERE status = 'Confirmed'
    GROUP BY event_id
) AS t ON e.event_id = t.event_id
SET e.available_seats = e.total_seats - COALESCE(t.confirmed_count, 0)
WHERE e.event_id >= 0;  -- uses the primary key with a constant to satisfy safe update mode (works in safe-update mode)

-- ========== CRUD OPERATION EXAMPLES ==========
-- Create: add a new event
INSERT INTO events (event_name, event_date, venue_id, organizer_id, ticket_price, total_seats, available_seats)
VALUES ('Photography Meetup','2025-12-15 16:00:00',1,3,149.00,200,200);

-- Read: list events
SELECT * FROM events ORDER BY event_date ASC;

-- Update: change ticket price for an event
UPDATE events SET ticket_price = 549.00 WHERE event_id = 1;

-- Delete: remove a cancelled ticket
DELETE FROM tickets WHERE ticket_id = 6;

-- ========== TASK QUERIES (examples matching project instructions) ==========
-- 1) Use WHERE, HAVING, LIMIT
-- Get upcoming events happening in Mumbai
SELECT e.event_id, e.event_name, e.event_date, v.location
FROM events e
JOIN venues v ON e.venue_id = v.venue_id
WHERE v.location = 'Mumbai' AND e.event_date >= NOW()
ORDER BY e.event_date;

-- Retrieve top 5 highest revenue-generating events (revenue from payments with Success)
SELECT
  e.event_id, e.event_name,
  COALESCE(SUM(p.amount_paid),0) AS total_revenue
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id AND p.payment_status = 'Success'
GROUP BY e.event_id
ORDER BY total_revenue DESC
LIMIT 5;

-- Find attendees who booked tickets in the last 7 days
SELECT a.attendee_id, a.name, t.booking_date
FROM attendees a
JOIN tickets t ON a.attendee_id = t.attendee_id
WHERE t.booking_date >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- 2) Apply SQL Operators (AND, OR, NOT)
-- Retrieve events scheduled in December AND have more than 50% available seats
SELECT e.event_id, e.event_name, e.event_date, e.available_seats, e.total_seats
FROM events e
WHERE MONTH(e.event_date) = 12
  AND e.available_seats > (0.5 * e.total_seats);

-- List attendees who have booked a ticket OR have a pending payment
SELECT DISTINCT a.attendee_id, a.name, a.email
FROM attendees a
LEFT JOIN tickets t ON a.attendee_id = t.attendee_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id
WHERE t.ticket_id IS NOT NULL OR p.payment_status = 'Pending';

-- Identify events that are NOT fully booked
SELECT e.*
FROM events e
WHERE e.available_seats > 0;

-- 3) Sorting & Grouping (ORDER BY, GROUP BY)
-- Count the number of attendees per event (confirmed tickets only)
SELECT e.event_id, e.event_name, COUNT(t.ticket_id) AS confirmed_attendees
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id AND t.status = 'Confirmed'
GROUP BY e.event_id
ORDER BY confirmed_attendees DESC;

-- Show total revenue generated per event
SELECT e.event_id, e.event_name, COALESCE(SUM(p.amount_paid),0) AS revenue
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id AND p.payment_status = 'Success'
GROUP BY e.event_id
ORDER BY revenue DESC;

-- 4) Aggregate Functions (SUM, AVG, MAX, MIN, COUNT)
-- Calculate total revenue from all events
SELECT COALESCE(SUM(amount_paid),0) AS total_revenue FROM payments WHERE payment_status = 'Success';

-- Find event with highest number of attendees (confirmed)
SELECT e.event_id, e.event_name, COUNT(t.ticket_id) AS total_attendees
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id AND t.status = 'Confirmed'
GROUP BY e.event_id
ORDER BY total_attendees DESC
LIMIT 1;

-- Compute average ticket price across all events
SELECT AVG(ticket_price) AS avg_ticket_price FROM events;

-- 5) Joins examples
-- Retrieve event details with venue info (INNER JOIN)
SELECT e.event_id, e.event_name, v.venue_name, v.location, e.event_date
FROM events e
INNER JOIN venues v ON e.venue_id = v.venue_id;

-- Get list of attendees who booked but did not complete payment (LEFT JOIN)
SELECT a.attendee_id, a.name, t.ticket_id, p.payment_status
FROM attendees a
JOIN tickets t ON a.attendee_id = t.attendee_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id
WHERE p.payment_status IS NULL OR p.payment_status <> 'Success';

-- Identify events without any attendees using LEFT JOIN & HAVING
SELECT e.event_id, e.event_name, COUNT(t.ticket_id) AS booked_count
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id
GROUP BY e.event_id
HAVING booked_count = 0;

-- 6) Subqueries
-- Find events that generated revenue above the average ticket sales
SELECT e.event_id, e.event_name, COALESCE(SUM(p.amount_paid),0) AS revenue
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id AND p.payment_status = 'Success'
GROUP BY e.event_id
HAVING revenue > (
  SELECT AVG(total_rev) FROM (
    SELECT COALESCE(SUM(p2.amount_paid),0) AS total_rev
    FROM events e2
    LEFT JOIN tickets t2 ON e2.event_id = t2.event_id
    LEFT JOIN payments p2 ON t2.ticket_id = p2.ticket_id AND p2.payment_status = 'Success'
    GROUP BY e2.event_id
  ) AS derived
);

-- Identify attendees who have booked tickets for multiple events
SELECT a.attendee_id, a.name, COUNT(DISTINCT t.event_id) AS events_booked
FROM attendees a
JOIN tickets t ON a.attendee_id = t.attendee_id
GROUP BY a.attendee_id
HAVING events_booked > 1;

-- Retrieve organizers who have managed more than 3 events
SELECT o.organizer_id, o.organizer_name, COUNT(e.event_id) AS events_managed
FROM organizers o
JOIN events e ON o.organizer_id = e.organizer_id
GROUP BY o.organizer_id
HAVING events_managed > 3;

-- 7) Date & Time Functions
-- Extract month from event_date
SELECT event_id, event_name, MONTH(event_date) AS event_month FROM events;

-- Calculate days remaining for upcoming events
SELECT event_id, event_name, DATEDIFF(event_date, NOW()) AS days_remaining
FROM events
WHERE event_date > NOW();

-- Format payment_date
SELECT payment_id, DATE_FORMAT(payment_date, '%Y-%m-%d %H:%i:%s') AS payment_date_formatted FROM payments;

-- 8) String manipulation functions
-- Convert organizer names to uppercase
SELECT organizer_id, UPPER(organizer_name) AS organizer_upper FROM organizers;

-- Remove extra spaces from attendee names (TRIM)
SELECT attendee_id, TRIM(name) AS clean_name FROM attendees;

-- Replace NULL email fields with 'Not Provided'
SELECT attendee_id, COALESCE(email, 'Not Provided') AS email_safe FROM attendees;

-- 9) Window functions (MySQL 8+)
-- Rank events by total revenue
SELECT
  event_id, event_name, revenue,
  RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM (
  SELECT e.event_id, e.event_name, COALESCE(SUM(p.amount_paid),0) AS revenue
  FROM events e
  LEFT JOIN tickets t ON e.event_id = t.event_id
  LEFT JOIN payments p ON t.ticket_id = p.ticket_id AND p.payment_status = 'Success'
  GROUP BY e.event_id
) AS sub;

-- Display cumulative sum of ticket sales per event (ordered by event_date)
SELECT
  event_id, event_name, event_date, revenue,
  SUM(revenue) OVER (ORDER BY event_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM (
  SELECT e.event_id, e.event_name, e.event_date, COALESCE(SUM(p.amount_paid),0) AS revenue
  FROM events e
  LEFT JOIN tickets t ON e.event_id = t.event_id
  LEFT JOIN payments p ON t.ticket_id = p.ticket_id AND p.payment_status = 'Success'
  GROUP BY e.event_id
) AS revs;

-- Running total of attendees registered per event (by event_date)
SELECT
  event_id, event_name, event_date, confirmed_attendees,
  SUM(confirmed_attendees) OVER (ORDER BY event_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_attendees
FROM (
  SELECT e.event_id, e.event_name, e.event_date, COUNT(t.ticket_id) AS confirmed_attendees
  FROM events e
  LEFT JOIN tickets t ON e.event_id = t.event_id AND t.status = 'Confirmed'
  GROUP BY e.event_id
) AS counts;

-- 10) CASE expressions
-- Categorize events based on ticket sales
SELECT
  event_id,
  event_name,
  total_seats,
  available_seats,
  CASE
    WHEN available_seats < 0.2 * total_seats THEN 'High Demand'
    WHEN available_seats BETWEEN 0.2 * total_seats AND 0.5 * total_seats THEN 'Moderate Demand'
    ELSE 'Low Demand'
  END AS demand_category
FROM events;

-- Assign human-readable payment status
SELECT payment_id, payment_status,
  CASE
    WHEN payment_status = 'Success' THEN 'Successful'
    WHEN payment_status = 'Failed' THEN 'Failed'
    ELSE 'Pending'
  END AS payment_readable
FROM payments;

-- ========== Additional Example Reports ==========
-- Most popular events (by confirmed attendees)
SELECT e.event_id, e.event_name, COUNT(t.ticket_id) AS confirmed_attendees
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id AND t.status = 'Confirmed'
GROUP BY e.event_id
ORDER BY confirmed_attendees DESC
LIMIT 10;

-- Highest revenue-generating events (detailed)
SELECT e.event_id, e.event_name, v.venue_name, o.organizer_name,
  COALESCE(SUM(p.amount_paid),0) AS total_revenue,
  COUNT(DISTINCT t.attendee_id) AS unique_attendees
FROM events e
LEFT JOIN venues v ON e.venue_id = v.venue_id
LEFT JOIN organizers o ON e.organizer_id = o.organizer_id
LEFT JOIN tickets t ON e.event_id = t.event_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id AND p.payment_status = 'Success'
GROUP BY e.event_id
ORDER BY total_revenue DESC
LIMIT 10;

-- ========== CLEANUP (optional) ==========
-- DROP TRIGGERS
-- DROP TRIGGER IF EXISTS trg_after_ticket_insert;
-- DROP TRIGGER IF EXISTS trg_after_ticket_update;

-- DROP DATABASE event_management;

