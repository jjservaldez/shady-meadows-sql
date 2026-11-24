# Shady Meadows B&B: Data Validation with SQL

SQL queries that answer business questions and validate data quality for a hotel booking system. It's the data-layer companion to my manual and AI-assisted testing of the [Shady Meadows booking flow](https://automationintesting.online).

**Author:** Jose Serna, QA Engineer

## Why this project

UI testing tells you what the user sees. Some defects only show up clearly in the data. Two examples:

- **Double submit:** a double click on "Reserve Now" looks like one "Booking Confirmed" on screen, but it can leave two identical rows in the database.
- **Inflated reports:** an occupancy report can count the same night twice without anyone noticing.

The public demo doesn't expose its database. So I built a **local replica** of its data model, based on the fields of the real API (`GET /api/room`, `POST /api/booking`). The seed data mixes clean bookings with records that reproduce, at the data level, the bugs I found testing the UI. Each query is tied to a bug or a test case, so the SQL doesn't stand on its own: it's part of the same testing work.

## How to run it

Requires Python 3 (SQLite comes with it). No installation needed.

```bash
python3 run.py              # builds shady_meadows.db and prints every query result
python3 run.py --out results.md
python3 run.py --check      # checks the data-quality findings against the expected values
```

You can also open `shady_meadows.db` in any SQLite client (DB Browser for SQLite, DBeaver, the VS Code extension) and run the queries one by one from `queries.sql`.

## Data model

| Table | Columns | Notes |
|---|---|---|
| `room` | roomid, room_name, type, accessible, room_price | 3 rooms: Single £100, Double £150, Suite £225 |
| `booking` | bookingid, roomid, firstname, lastname, email, phone, depositpaid, checkin, checkout, created_at | `checkout` is the day the guest leaves; `created_at` in UTC |
| `fee` | name, amount | cleaning £25, service £15 (same as the UI's Price Summary) |

**Rules used across the queries:**
- **Nights** = checkout − checkin.
- **Two stays overlap** when `a.checkin < b.checkout AND b.checkin < a.checkout`. A check-in on another stay's check-out day is **not** an overlap.
- **Reference date:** 2026-11-23.

## Planted data

| Bookings | What it reproduces | Link to UI testing |
|---|---|---|
| 5 & 6 | Overlapping stays in the Double room | BUG-01 (rejected booking crashes the page) |
| 7 & 8 | Two tabs book the same Suite one second apart | TC-033 |
| 9 & 10 | Same guest, same booking, one second apart | TC-034 (double submit) |
| 11, 12 | Check-out before check-in; check-out on the same day | BUG-02 (negative / zero nights) |
| 13, 14 | Names that are only digits; names that contain digits | BUG-04 |
| 15, 16, 17, 26 | Firstname too short (raw and with spaces), phone too short, bad email | AC4–AC7, TC-018 |
| 18 | Stay in the past, booked after it ended | CAND-08 |
| 19 | Booking for room 99, which doesn't exist | TC-041 |
| 20 & 21 | Back-to-back stays (valid, must **not** be flagged) | TC-015 |

## Queries

| # | Business question | Technique | Expected result |
|---|---|---|---|
| Q01 | Are there two bookings for the same room on the same nights? | Self-join, interval overlap | 3 pairs: (5,6), (7,8), (9,10). Back-to-back 20/21 is not flagged. |
| Q02 | Which bookings have check-out on or before check-in? | Date arithmetic | 11 (−2 nights), 12 (0 nights) |
| Q03 | Which names contain digits, or are only digits? | `GLOB` patterns, `CASE` | 13 digits only, 14 contains digits |
| Q04 | Which stored bookings break the form rules? | `UNION ALL` of rule checks, `TRIM` | 15, 16 (firstname), 17 (phone), 26 (email) |
| Q05 | Did someone create the same booking twice within seconds? | Self-join on a business key + time window | 9 → 10, 1 second apart |
| Q06 | Are there bookings for rooms that don't exist? | `LEFT JOIN … IS NULL` | 19 (room 99) |
| Q07 | Which bookings were created after their check-in date? | Date comparison | 18, 44 days late |
| Q08 | How much should each valid booking cost? | Join + `CROSS JOIN` of fees | Oracle for the Price Summary. Example: booking 3, Suite × 3 nights = £715 (TC-003). |
| Q09 | Which rooms are free from 1 to 3 March 2027? | `NOT EXISTS` | Single and Double. The Suite is taken (oracle for TC-031/TC-033). |
| Q10 | How many nights was each room occupied in December 2026? | Recursive CTE calendar, `COUNT(DISTINCT)` | Double: **10 booked nights vs. 9 occupied**. The difference is the overlap from Q01. |
| Q11 | Which guests booked more than once? | `GROUP BY … HAVING` | maria.gonzalez: 3 bookings but only 2 distinct stays (one is a duplicate) |
| Q12 | How many records fail each data check? | Summary with `UNION ALL` | One row per check (used by `--check`) |

The full output is in `results.md`.

## What the data shows

1. **Bad data distorts business metrics without any error.** In Q10, summing nights per booking says the Double room had 10 nights in December, but only 9 calendar nights were occupied. Nothing crashes; the report is just wrong. That's why Q10 shows both numbers.
2. **Duplicates look like loyal customers.** In Q11, Maria seems to be the top repeat guest, but one of her 3 bookings is the double submit from Q05. A CRM report built on this data would reward a bug.
3. **The query can be the test oracle.** Q08 and Q09 compute what the UI *should* show (price and availability). The same logic gives the expected result for TC-003, TC-031 and TC-033.
4. **Validation has to be checked on the server as well.** Every row in Q04 is a value the UI form rejects. If it reaches the database, someone went around the form (a direct API call, untrimmed input), and only the data shows it.

## The `--check` mode: testing the queries themselves

`run.py --check` compares the findings in Q12 with the expected values for this seed data. If someone changes a query or the data, the check shows exactly which finding moved.

To confirm the check actually catches problems, I inserted one extra overlapping booking. The result was `FAIL Q01 overlapping pairs: expected 3, got 4`. A check that never fails proves nothing; this one does fail when it should.

## Limitations

- **This is a replica, not the real database.** The model follows the public API, but the real schema may differ (for example, it may store email and phone in another table).
- **Dates are stored as ISO text,** which is the SQLite convention. In PostgreSQL or MySQL these would be `DATE`/`TIMESTAMP` columns, and the date functions change (`julianday` → `checkout - checkin` or `DATEDIFF`).
- **Foreign keys are off on purpose,** so the orphan booking in Q06 can exist. In production they should be on.

## Related work

- AI test-case agent and its evaluation: https://github.com/jjservaldez/ai-test-case-agent
- Bug reports and test plan for the booking flow (same portfolio)
