-- Seed data for Shady Meadows B&B (SQLite)
-- Clean bookings mixed with records that reproduce, at the data
-- level, the bugs and risks found while testing the UI
-- (see the "Planted data" table in README.md).
-- Reference date for every query: 2026-11-23.

INSERT INTO room (roomid, room_name, type, accessible, room_price) VALUES
  (1, '101', 'Single', 1, 100),
  (2, '102', 'Double', 1, 150),
  (3, '103', 'Suite',  1, 225);

INSERT INTO fee (name, amount) VALUES
  ('cleaning', 25),
  ('service',  15);

INSERT INTO booking (bookingid, roomid, firstname, lastname, email, phone, depositpaid, checkin, checkout, created_at) VALUES
  -- Clean bookings
  ( 1, 1, 'Maria',  'Gonzalez',      'maria.gonzalez@example.com',  '+523312345678',      1, '2026-12-14', '2026-12-16', '2026-11-20 10:00:00'),
  ( 2, 2, 'Lucia',  'Ramirez',       'lucia.ramirez@example.com',   '+523398765432',      1, '2026-11-30', '2026-12-02', '2026-11-18 09:15:00'),
  ( 3, 3, 'Oliver', 'Smith',         'oliver.smith@example.co.uk',  '+44 (20) 7946-0958', 0, '2026-12-07', '2026-12-10', '2026-11-19 14:30:00'),
  ( 4, 1, 'José',   'O''Brien-Núñez', 'jose.obrien@example.com',    '+523312345678',      1, '2026-12-30', '2027-01-02', '2026-11-21 08:00:00'),
  (22, 1, 'Daniel', 'Torres',        'daniel.torres@example.com',   '+523355556666',      1, '2026-11-02', '2026-11-05', '2026-10-20 16:45:00'),
  (23, 3, 'Emma',   'Clarke',        'emma.clarke@example.com',     '+447700900123',      1, '2026-11-27', '2026-11-29', '2026-11-15 13:00:00'),
  (24, 1, 'Sam',    'Patel',         'sam.patel@example.com',       '+447700900456',      1, '2026-12-01', '2026-12-03', '2026-11-16 09:30:00'),
  (25, 2, 'Noah',   'Brown',         'noah.brown@example.com',      '+447700900789',      0, '2026-12-28', '2027-01-01', '2026-11-17 19:20:00'),

  -- Overlapping bookings in the same room (BUG-01 scenario: backend should reject)
  ( 5, 2, 'Ana',    'Lee',           'a@b.co',                      '01234567890',        0, '2026-12-20', '2026-12-23', '2026-11-22 12:00:00'),
  ( 6, 2, 'Pedro',  'Ruiz',          'pedro.ruiz@example.com',      '+523311112222',      1, '2026-12-22', '2026-12-24', '2026-11-22 12:30:00'),

  -- Two tabs, same room and dates, one second apart (TC-033)
  ( 7, 3, 'Carla',  'Mendez',        'carla.mendez@example.com',    '+523322223333',      1, '2027-03-01', '2027-03-03', '2026-11-22 18:00:01'),
  ( 8, 3, 'Luis',   'Herrera',       'luis.herrera@example.com',    '+523344445555',      1, '2027-03-01', '2027-03-03', '2026-11-22 18:00:02'),

  -- Double submit: same guest, room and dates, 1 second apart (TC-034)
  ( 9, 1, 'Maria',  'Gonzalez',      'maria.gonzalez@example.com',  '+523312345678',      0, '2027-03-08', '2027-03-10', '2026-11-22 19:10:00'),
  (10, 1, 'Maria',  'Gonzalez',      'maria.gonzalez@example.com',  '+523312345678',      0, '2027-03-08', '2027-03-10', '2026-11-22 19:10:01'),

  -- Invalid date ranges (BUG-02)
  (11, 1, 'Pablo',  'Negrete',       'pablo.negrete@example.com',   '+523300000000',      0, '2027-03-15', '2027-03-13', '2026-11-22 20:00:00'),
  (12, 2, 'Irene',  'Zamora',        'irene.zamora@example.com',    '+523300000001',      0, '2027-03-17', '2027-03-17', '2026-11-22 20:05:00'),

  -- Names with digits (BUG-04)
  (13, 1, '12345',  '67890',         'digits.only@example.com',     '+523312345678',      0, '2027-01-25', '2027-01-26', '2026-11-21 11:00:00'),
  (14, 1, 'Jos123', 'Gonzalez',      'jos123@example.com',          '+523312345678',      0, '2027-01-27', '2027-01-28', '2026-11-21 11:10:00'),

  -- Values that break the form rules (AC4–AC7): the backend should have rejected them
  (15, 2, 'Al',     'Gonzalez',      'al.gonzalez@example.com',     '+523312345678',      0, '2027-02-01', '2027-02-03', '2026-11-21 11:20:00'),
  (16, 2, '  Al  ', 'Gonzalez',      'al.spaces@example.com',       '+523312345678',      0, '2027-02-05', '2027-02-06', '2026-11-21 11:30:00'),
  (17, 3, 'Maria',  'Gonzalez',      'maria.g@example.com',         '0123456789',         0, '2027-02-10', '2027-02-12', '2026-11-21 11:40:00'),
  (26, 1, 'Maria',  'Gonzalez',      'maria@',                      '+523312345678',      0, '2027-02-15', '2027-02-17', '2026-11-21 11:50:00'),

  -- Stay in the past, booked after it ended (CAND-08)
  (18, 1, 'Hugo',   'Salas',         'hugo.salas@example.com',      '+523312345678',      0, '2026-10-10', '2026-10-12', '2026-11-23 02:50:00'),

  -- Booking for a room that does not exist (TC-041)
  (19, 99, 'Rosa',  'Vega',          'rosa.vega@example.com',       '+523312345678',      0, '2027-04-12', '2027-04-14', '2026-11-22 21:00:00'),

  -- Back-to-back: check-in on another booking's check-out day (TC-015, NOT an overlap)
  (20, 2, 'Marta',  'Ibarra',        'marta.ibarra@example.com',    '+523398765400',      1, '2027-02-22', '2027-02-24', '2026-11-21 12:00:00'),
  (21, 2, 'Lucia',  'Ramirez',       'lucia.ramirez@example.com',   '+523398765432',      1, '2027-02-24', '2027-02-26', '2026-11-21 12:05:00');
