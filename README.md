# 🎯 **Smart Event Management System – SQL Project**

A complete SQL-based database system designed to help event organizers manage events, venues, attendee registrations, ticket bookings, payments, and detailed analytical reports.
This project was created using **MySQL** and demonstrates real-world database design, relationships, constraints, CRUD operations, joins, aggregate functions, subqueries, window functions, and more.

---

## 📌 **Project Objective**

Develop a **Smart Event Management System** where organizers can:

* Manage events & venues
* Handle attendee registrations
* Monitor ticket sales
* Track payments
* Generate insights & analytical reports

The system covers:

✅ CRUD Operations
✅ Filtering, Sorting, Aggregation
✅ Primary/Foreign Keys
✅ Joins (INNER, LEFT, RIGHT, FULL OUTER simulation)
✅ Subqueries
✅ Window Functions
✅ Date & String Functions
✅ CASE expressions

---

## 🏗️ **Database Schema Overview**

### **1️⃣ Events**

| Column            | Description               |
| ----------------- | ------------------------- |
| event_id (PK)     | Unique event ID           |
| event_name        | Name of event             |
| event_date        | Date & time               |
| venue_id (FK)     | Linked to Venues          |
| organizer_id (FK) | Linked to Organizers      |
| ticket_price      | Price per ticket          |
| total_seats       | Total capacity            |
| available_seats   | Auto-updated via triggers |

---

### **2️⃣ Venues**

| Column        | Description      |
| ------------- | ---------------- |
| venue_id (PK) | Unique venue ID  |
| venue_name    | Venue name       |
| location      | City             |
| capacity      | Seating capacity |

---

### **3️⃣ Organizers**

| Column            | Description      |
| ----------------- | ---------------- |
| organizer_id (PK) | Unique ID        |
| organizer_name    | Organizer’s name |
| contact_email     | Email            |
| phone_number      | Phone number     |

---

### **4️⃣ Attendees**

| Column           | Description   |
| ---------------- | ------------- |
| attendee_id (PK) | Unique ID     |
| name             | Attendee name |
| email            | Email         |
| phone_number     | Phone number  |

---

### **5️⃣ Tickets**

| Column           | Description                     |
| ---------------- | ------------------------------- |
| ticket_id (PK)   | Ticket ID                       |
| event_id (FK)    | Linked to Events                |
| attendee_id (FK) | Linked to Attendees             |
| booking_date     | Booking timestamp               |
| status           | Confirmed / Cancelled / Pending |

**Constraint:** An attendee cannot book the same event twice (UNIQUE event_id + attendee_id).

---

### **6️⃣ Payments**

| Column          | Description                |
| --------------- | -------------------------- |
| payment_id (PK) | Payment ID                 |
| ticket_id (FK)  | Linked to Tickets          |
| amount_paid     | Payment amount             |
| payment_status  | Success / Failed / Pending |
| payment_date    | Timestamp                  |

---

## ⚙️ **Extra Features Included**

### ✔ Triggers

Automatically update *available_seats* whenever ticket status changes.

### ✔ Safe Update Mode Fix

The project includes a join-based update that works even in MySQL Safe Mode.

### ✔ Sample Data

All tables include realistic sample records for testing.

---

## 📚 **Project Functionalities**

### **1. CRUD Operations**

* Add / Update / Delete / Search

  * Events
  * Venues
  * Organizers
  * Attendees
  * Tickets

---

### **2. SQL Clauses**

* Retrieve events by city
* Find top revenue events
* Attendees who booked within last 7 days

---

### **3. SQL Operators (AND/OR/NOT)**

Examples include:

* December events with >50% seats left
* Attendees with ticket OR pending payment
* Events not fully booked

---

### **4. Sorting & Grouping**

* Events sorted by date
* Count attendees per event
* Total revenue per event

---

### **5. Aggregate Functions**

* SUM of total revenue
* MAX attendees
* AVG ticket price

---

### **6. Key Relationships**

* Prevent duplicate bookings
* Link payments to tickets

---

### **7. Joins**

* INNER JOIN: Event + Venue details
* LEFT JOIN: Booked tickets without successful payment
* RIGHT JOIN: Events without attendees
* FULL OUTER JOIN (simulated)

---

### **8. Subqueries**

Examples:

* Events with above-average revenue
* Attendees booking multiple events
* Organizers managing >3 events

---

### **9. Date & Time Functions**

* Extract month from event date
* Days remaining for event
* Format payment date

---

### **10. String Functions**

* Uppercase organizer names
* Trim attendee names
* Replace NULL with “Not Provided”

---

### **11. Window Functions**

* Rank events by revenue
* Cumulative revenue
* Running total attendees

---

### **12. CASE Expressions**

* Categorize events as High / Moderate / Low demand
* User-friendly payment statuses

---

## 📁 **File Included**

### `event_management.sql`

Contains:

* Schema creation
* Constraints
* Triggers
* Sample data
* All required queries
* Reporting queries

Download the SQL file:
👉 **[event_management.sql](sandbox:/mnt/data/event_management.sql)**

---

## 🚀 **How to Run the Project**

### **1. Create database**

```sql
SOURCE path/to/event_management.sql;
```

### **2. View tables**

```sql
SHOW TABLES;
```

### **3. Run any query from the script**

Examples:

```sql
SELECT * FROM events;
SELECT * FROM payments WHERE payment_status='Success';
```

---


