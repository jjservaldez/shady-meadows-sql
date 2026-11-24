-- Shady Meadows B&B: SQL queries with business context
-- Each query starts with: business question, why it matters for QA,
-- and what it is linked to (bug / test case).
-- Rules used across queries:
--   * nights = checkout - checkin (checkout is the day the guest leaves)
--   * two stays overlap when a.checkin < b.checkout AND b.checkin < a.checkout
--     (so a check-in on another stay's check-out day is NOT an overlap)
--   * a "valid range" means checkout > checkin
--   * reference date: 2026-11-23

-- name: Q01_overlapping_bookings
-- Question: Are there two bookings for the same room on the same nights?
-- Why it matters: the core rule of a booking system (AC10). If the data has
--   overlaps, the backend let a double booking through. In the UI this shows
--   up as BUG-01 (the rejection crashes the page) or, worse, as a silent overbooking.
-- Linked to: BUG-01, TC-031, TC-032, TC-033
SELECT a.roomid,
       a.bookingid  AS booking_a, a.checkin AS a_in, a.checkout AS a_out,
       b.bookingid  AS booking_b, b.checkin AS b_in, b.checkout AS b_out,
       CAST(julianday(MIN(a.checkout, b.checkout)) - julianday(MAX(a.checkin, b.checkin)) AS INTEGER) AS nights_overlapping
FROM booking a
JOIN booking b
  ON  a.roomid = b.roomid
  AND a.bookingid < b.bookingid          -- each pair once
  AND a.checkin  < b.checkout
  AND b.checkin  < a.checkout
WHERE a.checkout > a.checkin
  AND b.checkout > b.checkin             -- invalid ranges are handled in Q02
ORDER BY a.roomid, a.bookingid;

-- name: Q02_invalid_date_ranges
-- Question: Which bookings have a check-out on or before the check-in?
-- Why it matters: those stays have 0 or negative nights. The Price Summary
--   would show negative totals or fees only (AC11).
-- Linked to: BUG-02, TC-035, TC-036, TC-048
SELECT bookingid, roomid, checkin, checkout,
       CAST(julianday(checkout) - julianday(checkin) AS INTEGER) AS nights
FROM booking
WHERE checkout <= checkin
ORDER BY bookingid;

-- name: Q03_names_with_digits
-- Question: Which guests have digits in their name, and which names are only digits?
-- Why it matters: the ACs only define length, so the UI accepts "12345".
--   The data shows how widespread the problem is before asking the PO for a rule.
-- Linked to: BUG-04, TC-017
SELECT bookingid, firstname, lastname,
       CASE WHEN firstname NOT GLOB '*[^0-9]*' AND lastname NOT GLOB '*[^0-9]*'
            THEN 'digits only' ELSE 'contains digits' END AS issue
FROM booking
WHERE firstname GLOB '*[0-9]*' OR lastname GLOB '*[0-9]*'
ORDER BY bookingid;

-- name: Q04_form_rule_violations
-- Question: Which stored bookings break the form rules (AC4–AC7)?
-- Why it matters: the UI checks these rules, but the backend is the last line
--   of defense. Any row here means a request got around the validation
--   (direct API call, a field that isn't trimmed, etc.).
--   Lengths are measured after TRIM (TC-018).
-- Linked to: AC4–AC7, TC-018, TC-019, TC-026, TC-027
SELECT bookingid, 'firstname length' AS rule, '[' || firstname || ']' AS value,
       LENGTH(TRIM(firstname)) AS measured, '3-18' AS allowed
FROM booking WHERE LENGTH(TRIM(firstname)) NOT BETWEEN 3 AND 18
UNION ALL
SELECT bookingid, 'lastname length', '[' || lastname || ']',
       LENGTH(TRIM(lastname)), '3-30'
FROM booking WHERE LENGTH(TRIM(lastname)) NOT BETWEEN 3 AND 30
UNION ALL
SELECT bookingid, 'phone length', phone,
       LENGTH(phone), '11-21'
FROM booking WHERE LENGTH(phone) NOT BETWEEN 11 AND 21
UNION ALL
SELECT bookingid, 'email format', email,
       NULL, 'x@y.z'
FROM booking WHERE email NOT LIKE '%_@_%._%'
ORDER BY bookingid, rule;

-- name: Q05_probable_double_submits
-- Question: Did the same guest create the same booking twice within a few seconds?
-- Why it matters: that is the trace of a double click on "Reserve Now" without
--   protection (the button isn't disabled, there's no idempotency). In the UI
--   it's hard to see without Admin access; in the data it's obvious.
-- Linked to: TC-034, TC-053
SELECT a.bookingid AS first_booking, b.bookingid AS duplicate,
       a.email, a.roomid, a.checkin, a.checkout,
       CAST(ROUND((julianday(b.created_at) - julianday(a.created_at)) * 86400) AS INTEGER) AS seconds_apart
FROM booking a
JOIN booking b
  ON  a.bookingid < b.bookingid
  AND a.email    = b.email
  AND a.roomid   = b.roomid
  AND a.checkin  = b.checkin
  AND a.checkout = b.checkout
WHERE (julianday(b.created_at) - julianday(a.created_at)) * 86400 <= 10
ORDER BY a.bookingid;

-- name: Q06_orphan_bookings
-- Question: Are there bookings for rooms that don't exist?
-- Why it matters: referential integrity. The UI should not allow booking
--   /reservation/99 (TC-041). If it happens, those bookings don't show up
--   in any report by room.
-- Linked to: TC-041
SELECT b.bookingid, b.roomid, b.firstname, b.lastname, b.checkin, b.checkout
FROM booking b
LEFT JOIN room r ON r.roomid = b.roomid
WHERE r.roomid IS NULL;

-- name: Q07_booked_after_stay_started
-- Question: Which bookings were created after their check-in date?
-- Why it matters: it means the system accepts stays in the past (CAND-08).
--   A booking for today is allowed, so only check-ins before the creation day count.
-- Linked to: CAND-08, TC-037
SELECT bookingid, roomid, checkin, checkout, created_at,
       CAST(julianday(DATE(created_at)) - julianday(checkin) AS INTEGER) AS days_late
FROM booking
WHERE checkin < DATE(created_at)
ORDER BY bookingid;

-- name: Q08_price_summary_oracle
-- Question: How much should each valid booking cost?
-- Why it matters: it's the test oracle for the Price Summary
--   (rate x nights + cleaning fee + service fee). Example: booking 3, Suite
--   for 3 nights, should be £715 (TC-003). Any total in the UI that doesn't
--   match this table is a bug.
-- Linked to: AC2, TC-001, TC-003, TC-011, TC-012
WITH fees AS (SELECT SUM(amount) AS total_fees FROM fee)
SELECT b.bookingid, r.type, b.checkin, b.checkout,
       CAST(julianday(b.checkout) - julianday(b.checkin) AS INTEGER) AS nights,
       r.room_price,
       r.room_price * CAST(julianday(b.checkout) - julianday(b.checkin) AS INTEGER) AS room_subtotal,
       f.total_fees,
       r.room_price * CAST(julianday(b.checkout) - julianday(b.checkin) AS INTEGER) + f.total_fees AS expected_total
FROM booking b
JOIN room r ON r.roomid = b.roomid
CROSS JOIN fees f
WHERE b.checkout > b.checkin
ORDER BY b.bookingid;

-- name: Q09_availability_for_range
-- Question: Which rooms are free from 2027-03-01 to 2027-03-03?
-- Why it matters: it reproduces the logic of "Check Availability" on the home
--   page. It serves as the oracle for TC-031/TC-033: a room with an overlapping
--   booking should not be listed.
-- Linked to: AC10, TC-031, TC-033, TC-042
WITH params AS (SELECT '2027-03-01' AS req_in, '2027-03-03' AS req_out)
SELECT r.roomid, r.type, r.room_price
FROM room r, params p
WHERE NOT EXISTS (
    SELECT 1 FROM booking b
    WHERE b.roomid   = r.roomid
      AND b.checkout > b.checkin
      AND b.checkin  < p.req_out
      AND p.req_in   < b.checkout
)
ORDER BY r.roomid;

-- name: Q10_december_occupancy
-- Question: How many nights was each room occupied in December 2026?
-- Why it matters: it's a typical business report, and it shows how bad data
--   distorts metrics. Adding up nights per booking counts an overlap twice;
--   counting occupied calendar days does not. The difference between the two
--   columns is exactly the overlapping nights from Q01.
-- Linked to: Q01 (overlaps inflate the metric)
WITH RECURSIVE days(d) AS (
    SELECT '2026-12-01'
    UNION ALL
    SELECT DATE(d, '+1 day') FROM days WHERE d < '2026-12-31'
),
booked AS (            -- nights per booking clipped to December (double-counts overlaps)
    SELECT b.roomid,
           SUM(MAX(0, julianday(MIN(b.checkout, '2027-01-01')) - julianday(MAX(b.checkin, '2026-12-01')))) AS booked_nights
    FROM booking b
    WHERE b.checkout > b.checkin
    GROUP BY b.roomid
),
occupied AS (          -- distinct calendar nights with at least one guest
    SELECT b.roomid, COUNT(DISTINCT days.d) AS occupied_nights
    FROM days
    JOIN booking b
      ON days.d >= b.checkin AND days.d < b.checkout
    WHERE b.checkout > b.checkin
    GROUP BY b.roomid
)
SELECT r.roomid, r.type,
       CAST(COALESCE(bk.booked_nights, 0) AS INTEGER)  AS booked_nights,
       COALESCE(o.occupied_nights, 0)                 AS occupied_nights,
       ROUND(100.0 * COALESCE(o.occupied_nights, 0) / 31, 1) AS occupancy_pct
FROM room r
LEFT JOIN booked   bk ON bk.roomid = r.roomid
LEFT JOIN occupied o  ON o.roomid  = r.roomid
ORDER BY r.roomid;

-- name: Q11_repeat_guests
-- Question: Which guests have booked more than once?
-- Why it matters: a typical loyalty/CRM report. The trap: duplicates from a
--   double submit (Q05) inflate the count. Comparing total vs. distinct stays
--   separates loyal guests from duplicated data.
-- Linked to: Q05
SELECT email,
       COUNT(*) AS bookings,
       COUNT(DISTINCT roomid || '|' || checkin || '|' || checkout) AS distinct_stays
FROM booking
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY bookings DESC, email;

-- name: Q12_data_quality_summary
-- Question: How many records fail each data check?
-- Why it matters: a one-screen summary for a status report or a dashboard.
--   Each row points to the detailed query.
SELECT 'Q01 overlapping pairs' AS check_name, COUNT(*) AS findings FROM (
    SELECT 1 FROM booking a JOIN booking b
      ON a.roomid = b.roomid AND a.bookingid < b.bookingid
     AND a.checkin < b.checkout AND b.checkin < a.checkout
    WHERE a.checkout > a.checkin AND b.checkout > b.checkin)
UNION ALL
SELECT 'Q02 invalid date ranges', COUNT(*) FROM booking WHERE checkout <= checkin
UNION ALL
SELECT 'Q03 names with digits', COUNT(*) FROM booking
 WHERE firstname GLOB '*[0-9]*' OR lastname GLOB '*[0-9]*'
UNION ALL
SELECT 'Q04 form rule violations', COUNT(*) FROM (
    SELECT bookingid FROM booking WHERE LENGTH(TRIM(firstname)) NOT BETWEEN 3 AND 18
    UNION ALL SELECT bookingid FROM booking WHERE LENGTH(TRIM(lastname)) NOT BETWEEN 3 AND 30
    UNION ALL SELECT bookingid FROM booking WHERE LENGTH(phone) NOT BETWEEN 11 AND 21
    UNION ALL SELECT bookingid FROM booking WHERE email NOT LIKE '%_@_%._%')
UNION ALL
SELECT 'Q05 probable double submits', COUNT(*) FROM booking a JOIN booking b
  ON a.bookingid < b.bookingid AND a.email = b.email AND a.roomid = b.roomid
 AND a.checkin = b.checkin AND a.checkout = b.checkout
 WHERE (julianday(b.created_at) - julianday(a.created_at)) * 86400 <= 10
UNION ALL
SELECT 'Q06 orphan bookings', COUNT(*) FROM booking b
  LEFT JOIN room r ON r.roomid = b.roomid WHERE r.roomid IS NULL
UNION ALL
SELECT 'Q07 booked after stay started', COUNT(*) FROM booking WHERE checkin < DATE(created_at);
