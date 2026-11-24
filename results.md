### Q01_overlapping_bookings
Question: Are there two bookings for the same room on the same nights?

| roomid | booking_a | a_in | a_out | booking_b | b_in | b_out | nights_overlapping |
|---|---|---|---|---|---|---|---|
| 1 | 9 | 2027-03-08 | 2027-03-10 | 10 | 2027-03-08 | 2027-03-10 | 2 |
| 2 | 5 | 2026-12-20 | 2026-12-23 | 6 | 2026-12-22 | 2026-12-24 | 1 |
| 3 | 7 | 2027-03-01 | 2027-03-03 | 8 | 2027-03-01 | 2027-03-03 | 2 |

### Q02_invalid_date_ranges
Question: Which bookings have a check-out on or before the check-in?

| bookingid | roomid | checkin | checkout | nights |
|---|---|---|---|---|
| 11 | 1 | 2027-03-15 | 2027-03-13 | -2 |
| 12 | 2 | 2027-03-17 | 2027-03-17 | 0 |

### Q03_names_with_digits
Question: Which guests have digits in their name, and which names are only digits?

| bookingid | firstname | lastname | issue |
|---|---|---|---|
| 13 | 12345 | 67890 | digits only |
| 14 | Jos123 | Gonzalez | contains digits |

### Q04_form_rule_violations
Question: Which stored bookings break the form rules (AC4–AC7)?

| bookingid | rule | value | measured | allowed |
|---|---|---|---|---|
| 15 | firstname length | [Al] | 2 | 3-18 |
| 16 | firstname length | [  Al  ] | 2 | 3-18 |
| 17 | phone length | 0123456789 | 10 | 11-21 |
| 26 | email format | maria@ | NULL | x@y.z |

### Q05_probable_double_submits
Question: Did the same guest create the same booking twice within a few seconds?

| first_booking | duplicate | email | roomid | checkin | checkout | seconds_apart |
|---|---|---|---|---|---|---|
| 9 | 10 | maria.gonzalez@example.com | 1 | 2027-03-08 | 2027-03-10 | 1 |

### Q06_orphan_bookings
Question: Are there bookings for rooms that don't exist?

| bookingid | roomid | firstname | lastname | checkin | checkout |
|---|---|---|---|---|---|
| 19 | 99 | Rosa | Vega | 2027-04-12 | 2027-04-14 |

### Q07_booked_after_stay_started
Question: Which bookings were created after their check-in date?

| bookingid | roomid | checkin | checkout | created_at | days_late |
|---|---|---|---|---|---|
| 18 | 1 | 2026-10-10 | 2026-10-12 | 2026-11-23 02:50:00 | 44 |

### Q08_price_summary_oracle
Question: How much should each valid booking cost?

| bookingid | type | checkin | checkout | nights | room_price | room_subtotal | total_fees | expected_total |
|---|---|---|---|---|---|---|---|---|
| 1 | Single | 2026-12-14 | 2026-12-16 | 2 | 100 | 200 | 40 | 240 |
| 2 | Double | 2026-11-30 | 2026-12-02 | 2 | 150 | 300 | 40 | 340 |
| 3 | Suite | 2026-12-07 | 2026-12-10 | 3 | 225 | 675 | 40 | 715 |
| 4 | Single | 2026-12-30 | 2027-01-02 | 3 | 100 | 300 | 40 | 340 |
| 5 | Double | 2026-12-20 | 2026-12-23 | 3 | 150 | 450 | 40 | 490 |
| 6 | Double | 2026-12-22 | 2026-12-24 | 2 | 150 | 300 | 40 | 340 |
| 7 | Suite | 2027-03-01 | 2027-03-03 | 2 | 225 | 450 | 40 | 490 |
| 8 | Suite | 2027-03-01 | 2027-03-03 | 2 | 225 | 450 | 40 | 490 |
| 9 | Single | 2027-03-08 | 2027-03-10 | 2 | 100 | 200 | 40 | 240 |
| 10 | Single | 2027-03-08 | 2027-03-10 | 2 | 100 | 200 | 40 | 240 |
| 13 | Single | 2027-01-25 | 2027-01-26 | 1 | 100 | 100 | 40 | 140 |
| 14 | Single | 2027-01-27 | 2027-01-28 | 1 | 100 | 100 | 40 | 140 |
| 15 | Double | 2027-02-01 | 2027-02-03 | 2 | 150 | 300 | 40 | 340 |
| 16 | Double | 2027-02-05 | 2027-02-06 | 1 | 150 | 150 | 40 | 190 |
| 17 | Suite | 2027-02-10 | 2027-02-12 | 2 | 225 | 450 | 40 | 490 |
| 18 | Single | 2026-10-10 | 2026-10-12 | 2 | 100 | 200 | 40 | 240 |
| 20 | Double | 2027-02-22 | 2027-02-24 | 2 | 150 | 300 | 40 | 340 |
| 21 | Double | 2027-02-24 | 2027-02-26 | 2 | 150 | 300 | 40 | 340 |
| 22 | Single | 2026-11-02 | 2026-11-05 | 3 | 100 | 300 | 40 | 340 |
| 23 | Suite | 2026-11-27 | 2026-11-29 | 2 | 225 | 450 | 40 | 490 |
| 24 | Single | 2026-12-01 | 2026-12-03 | 2 | 100 | 200 | 40 | 240 |
| 25 | Double | 2026-12-28 | 2027-01-01 | 4 | 150 | 600 | 40 | 640 |
| 26 | Single | 2027-02-15 | 2027-02-17 | 2 | 100 | 200 | 40 | 240 |

### Q09_availability_for_range
Question: Which rooms are free from 2027-03-01 to 2027-03-03?

| roomid | type | room_price |
|---|---|---|
| 1 | Single | 100 |
| 2 | Double | 150 |

### Q10_december_occupancy
Question: How many nights was each room occupied in December 2026?

| roomid | type | booked_nights | occupied_nights | occupancy_pct |
|---|---|---|---|---|
| 1 | Single | 6 | 6 | 19.4 |
| 2 | Double | 10 | 9 | 29.0 |
| 3 | Suite | 3 | 3 | 9.7 |

### Q11_repeat_guests
Question: Which guests have booked more than once?

| email | bookings | distinct_stays |
|---|---|---|
| maria.gonzalez@example.com | 3 | 2 |
| lucia.ramirez@example.com | 2 | 2 |

### Q12_data_quality_summary
Question: How many records fail each data check?

| check_name | findings |
|---|---|
| Q01 overlapping pairs | 3 |
| Q02 invalid date ranges | 2 |
| Q03 names with digits | 2 |
| Q04 form rule violations | 4 |
| Q05 probable double submits | 1 |
| Q06 orphan bookings | 1 |
| Q07 booked after stay started | 1 |
