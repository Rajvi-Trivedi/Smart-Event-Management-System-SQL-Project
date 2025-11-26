DROP DATABASE IF EXISTS event_management;
CREATE DATABASE event_management;
USE event_management;

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

CREATE TABLE venues (
  venue_id INT AUTO_INCREMENT PRIMARY KEY,
  venue_name VARCHAR(255) NOT NULL,
  location VARCHAR(255),
  capacity INT NOT NULL DEFAULT 0
);

CREATE TABLE organizers (
  organizer_id INT AUTO_INCREMENT PRIMARY KEY,
  organizer_name VARCHAR(255) NOT NULL,
  contact_email VARCHAR(255),
  phone_number VARCHAR(50)
);

CREATE TABLE attendees (
  attendee_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone_number VARCHAR(50)
);

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

CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  ticket_id INT NOT NULL,
  amount_paid DECIMAL(10,2) NOT NULL,
  payment_status ENUM('Success','Failed','Pending') DEFAULT 'Pending',
  payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE ON UPDATE CASCADE
);

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

INSERT INTO venues (venue_name, location, capacity) VALUES
('Grand Hall A','Mumbai',500),
('Open Grounds','Pune',1000),
('Conference Room 1','Mumbai',120),
('Auditorium X','Bangalore',800);

INSERT INTO organizers (organizer_name, contact_email, phone_number) VALUES
('Alpha Events','alpha@events.com','+91-9000000001'),
('Beta Creations','contact@beta.com','+91-9000000002'),
('Gamma Organizers',NULL,'+91-9000000003');

INSERT INTO events (event_name, event_date, venue_id, organizer_id, ticket_price, total_seats, available_seats) VALUES
('Tech Summit 2025','2025-12-05 10:00:00',1,1,499.00,500,500),
('Music Fest','2025-12-20 18:00:00',2,2,999.00,1000,1000),
('Startup Pitch','2025-11-15 09:30:00',3,1,199.00,120,120),
('Design Workshop','2025-11-10 14:00:00',3,3,299.00,120,120),
('Health Conference','2025-12-01 09:00:00',4,2,399.00,800,800);

INSERT INTO attendees (name, email, phone_number) VALUES
('Rohit Sharma','rohit@example.com','+91-9810000001'),
('Anita Desai', NULL, '+91-9810000002'),
('Priya Singh','priya@example.com',NULL),
('Vikram Patel','vikram@example.com','+91-9810000004'),
('Nisha Kapoor','nisha@example.com','+91-9810000005');

INSERT INTO tickets (event_id, attendee_id, booking_date, status) VALUES
(1,1,'2025-10-01 12:00:00','Confirmed'),
(1,2,'2025-10-02 13:00:00','Pending'),
(2,3,'2025-10-05 09:00:00','Confirmed'),
(2,4,'2025-10-06 10:00:00','Confirmed'),
(3,1,'2025-10-07 11:00:00','Confirmed'),
(4,5,'2025-10-08 12:00:00','Cancelled');

INSERT INTO payments (ticket_id, amount_paid, payment_status, payment_date) VALUES
(1,499.00,'Success','2025-10-01 12:05:00'),
(3,999.00,'Success','2025-10-05 09:10:00'),
(4,999.00,'Success','2025-10-06 10:15:00'),
(5,199.00,'Pending','2025-10-07 11:20:00'),
(6,299.00,'Failed','2025-10-08 12:30:00');

UPDATE events e
LEFT JOIN (
    SELECT event_id, COUNT(*) AS confirmed_count
    FROM tickets
    WHERE status = 'Confirmed'
    GROUP BY event_id
) AS t ON e.event_id = t.event_id
SET e.available_seats = e.total_seats - COALESCE(t.confirmed_count, 0)
WHERE e.event_id >= 0;  

INSERT INTO events (event_name, event_date, venue_id, organizer_id, ticket_price, total_seats, available_seats)
VALUES ('Photography Meetup','2025-12-15 16:00:00',1,3,149.00,200,200);

SELECT * FROM events ORDER BY event_date ASC;

UPDATE events SET ticket_price = 549.00 WHERE event_id = 1;

DELETE FROM tickets WHERE ticket_id = 6;

SELECT e.event_id, e.event_name, e.event_date, v.location
FROM events e
JOIN venues v ON e.venue_id = v.venue_id
WHERE v.location = 'Mumbai' AND e.event_date >= NOW()
ORDER BY e.event_date;

SELECT
  e.event_id, e.event_name,
  COALESCE(SUM(p.amount_paid),0) AS total_revenue
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id AND p.payment_status = 'Success'
GROUP BY e.event_id
ORDER BY total_revenue DESC
LIMIT 5;

SELECT a.attendee_id, a.name, t.booking_date
FROM attendees a
JOIN tickets t ON a.attendee_id = t.attendee_id
WHERE t.booking_date >= DATE_SUB(NOW(), INTERVAL 7 DAY);

SELECT e.event_id, e.event_name, e.event_date, e.available_seats, e.total_seats
FROM events e
WHERE MONTH(e.event_date) = 12
  AND e.available_seats > (0.5 * e.total_seats);

SELECT DISTINCT a.attendee_id, a.name, a.email
FROM attendees a
LEFT JOIN tickets t ON a.attendee_id = t.attendee_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id
WHERE t.ticket_id IS NOT NULL OR p.payment_status = 'Pending';

SELECT e.*
FROM events e
WHERE e.available_seats > 0;

SELECT e.event_id, e.event_name, COUNT(t.ticket_id) AS confirmed_attendees
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id AND t.status = 'Confirmed'
GROUP BY e.event_id
ORDER BY confirmed_attendees DESC;

SELECT e.event_id, e.event_name, COALESCE(SUM(p.amount_paid),0) AS revenue
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id AND p.payment_status = 'Success'
GROUP BY e.event_id
ORDER BY revenue DESC;

SELECT COALESCE(SUM(amount_paid),0) AS total_revenue FROM payments WHERE payment_status = 'Success';

SELECT e.event_id, e.event_name, COUNT(t.ticket_id) AS total_attendees
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id AND t.status = 'Confirmed'
GROUP BY e.event_id
ORDER BY total_attendees DESC
LIMIT 1;

SELECT AVG(ticket_price) AS avg_ticket_price FROM events;

SELECT e.event_id, e.event_name, v.venue_name, v.location, e.event_date
FROM events e
INNER JOIN venues v ON e.venue_id = v.venue_id;

SELECT a.attendee_id, a.name, t.ticket_id, p.payment_status
FROM attendees a
JOIN tickets t ON a.attendee_id = t.attendee_id
LEFT JOIN payments p ON t.ticket_id = p.ticket_id
WHERE p.payment_status IS NULL OR p.payment_status <> 'Success';

SELECT e.event_id, e.event_name, COUNT(t.ticket_id) AS booked_count
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id
GROUP BY e.event_id
HAVING booked_count = 0;

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

SELECT a.attendee_id, a.name, COUNT(DISTINCT t.event_id) AS events_booked
FROM attendees a
JOIN tickets t ON a.attendee_id = t.attendee_id
GROUP BY a.attendee_id
HAVING events_booked > 1;

SELECT o.organizer_id, o.organizer_name, COUNT(e.event_id) AS events_managed
FROM organizers o
JOIN events e ON o.organizer_id = e.organizer_id
GROUP BY o.organizer_id
HAVING events_managed > 3;

SELECT event_id, event_name, MONTH(event_date) AS event_month FROM events;

SELECT event_id, event_name, DATEDIFF(event_date, NOW()) AS days_remaining
FROM events
WHERE event_date > NOW();

SELECT payment_id, DATE_FORMAT(payment_date, '%Y-%m-%d %H:%i:%s') AS payment_date_formatted FROM payments;

SELECT organizer_id, UPPER(organizer_name) AS organizer_upper FROM organizers;

SELECT attendee_id, TRIM(name) AS clean_name FROM attendees;

SELECT attendee_id, COALESCE(email, 'Not Provided') AS email_safe FROM attendees;

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

SELECT
  event_id, event_name, event_date, confirmed_attendees,
  SUM(confirmed_attendees) OVER (ORDER BY event_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_attendees
FROM (
  SELECT e.event_id, e.event_name, e.event_date, COUNT(t.ticket_id) AS confirmed_attendees
  FROM events e
  LEFT JOIN tickets t ON e.event_id = t.event_id AND t.status = 'Confirmed'
  GROUP BY e.event_id
) AS counts;

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

SELECT payment_id, payment_status,
  CASE
    WHEN payment_status = 'Success' THEN 'Successful'
    WHEN payment_status = 'Failed' THEN 'Failed'
    ELSE 'Pending'
  END AS payment_readable
FROM payments;

SELECT e.event_id, e.event_name, COUNT(t.ticket_id) AS confirmed_attendees
FROM events e
LEFT JOIN tickets t ON e.event_id = t.event_id AND t.status = 'Confirmed'
GROUP BY e.event_id
ORDER BY confirmed_attendees DESC
LIMIT 10;

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

