-- Shady Meadows B&B: booking data model (SQLite)
-- Modeled on the public restful-booker-platform API
-- (GET /api/room, POST /api/booking). The real demo does not
-- expose its database; this is a local replica for practicing
-- data validation with SQL.

PRAGMA foreign_keys = OFF;  -- off on purpose: the seed includes an orphan booking to detect

DROP TABLE IF EXISTS booking;
DROP TABLE IF EXISTS room;

CREATE TABLE room (
    roomid      INTEGER PRIMARY KEY,
    room_name   TEXT    NOT NULL,          -- "101", "102", "103"
    type        TEXT    NOT NULL,          -- Single, Double, Suite
    accessible  INTEGER NOT NULL,          -- 0/1
    room_price  INTEGER NOT NULL           -- GBP per night
);

CREATE TABLE booking (
    bookingid    INTEGER PRIMARY KEY,
    roomid       INTEGER NOT NULL REFERENCES room(roomid),
    firstname    TEXT    NOT NULL,
    lastname     TEXT    NOT NULL,
    email        TEXT    NOT NULL,
    phone        TEXT    NOT NULL,
    depositpaid  INTEGER NOT NULL DEFAULT 0,
    checkin      TEXT    NOT NULL,         -- ISO date YYYY-MM-DD
    checkout     TEXT    NOT NULL,         -- ISO date YYYY-MM-DD (day the guest leaves)
    created_at   TEXT    NOT NULL          -- ISO datetime, UTC
);

-- Business constants shown in the Price Summary
DROP TABLE IF EXISTS fee;
CREATE TABLE fee (
    name    TEXT PRIMARY KEY,
    amount  INTEGER NOT NULL               -- GBP per booking
);
