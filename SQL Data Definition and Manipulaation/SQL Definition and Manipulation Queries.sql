SET ECHO ON



-- 1. Create the database for Continental Palms Hotel(CPH) in Oracle.
-- drop existing tables
DROP TABLE RoomType 		CASCADE CONSTRAINTS PURGE;
DROP TABLE RoomTypeAmenity 	CASCADE CONSTRAINTS PURGE;
DROP TABLE RoomPrice 		CASCADE CONSTRAINTS PURGE;
DROP TABLE Room 		CASCADE CONSTRAINTS PURGE;
DROP TABLE RoomAmenity 		CASCADE CONSTRAINTS PURGE;
DROP TABLE Department 		CASCADE CONSTRAINTS PURGE;
DROP TABLE Employee 		CASCADE CONSTRAINTS PURGE;
DROP TABLE Guest 		CASCADE CONSTRAINTS PURGE;
DROP TABLE Member 		CASCADE CONSTRAINTS PURGE;
DROP TABLE CreditCard  		CASCADE CONSTRAINTS PURGE;
DROP TABLE GuestCreditCard  	CASCADE CONSTRAINTS PURGE;
DROP TABLE Visit 		CASCADE CONSTRAINTS PURGE;
DROP TABLE VisitRequest 	CASCADE CONSTRAINTS PURGE;
DROP TABLE TransactionType 	CASCADE CONSTRAINTS PURGE;
DROP TABLE Transaction 		CASCADE CONSTRAINTS PURGE;

-- create new tables
CREATE TABLE RoomType (
	name		VARCHAR2(15) 	PRIMARY KEY,
	description	VARCHAR2(30),
	roomSize	NUMBER(3)	CHECK (roomSize BETWEEN 200 AND 900)
);

CREATE TABLE RoomTypeAmenity (
	roomType	VARCHAR2(15) 	REFERENCES RoomType, 
	amenity		VARCHAR2(100),
	PRIMARY KEY (roomType, amenity)
);

CREATE TABLE RoomPrice (
	roomType	VARCHAR2(15) 	REFERENCES RoomType, 
	pricingDate	DATE,
	price		NUMBER(6,2)	CHECK (price BETWEEN 50 AND 400),
	PRIMARY KEY (roomType, pricingDate)
);

CREATE TABLE Room (
	no		NUMBER(3) 	PRIMARY KEY,
	floor		NUMBER(1) 	CHECK (floor BETWEEN 1 AND 5),
	wing		CHAR(1) 	CHECK (wing IN ('E', 'W', 'C')),
	roomView	CHAR(1) 	CHECK (roomView IN ('O', 'G', 'C')),
	roomType	VARCHAR2(15) 	NOT NULL REFERENCES RoomType
);

CREATE TABLE RoomAmenity (
	room		NUMBER(3) 	REFERENCES Room, 
	amenity		VARCHAR2(100),
	PRIMARY KEY (room, amenity)
);

CREATE TABLE Department (
	name		VARCHAR2(20) 	PRIMARY KEY,
	extension	NUMBER(3)	CHECK (extension BETWEEN 100 AND 999),
	fax		NUMBER(10),
	managerNo	NUMBER(3) 	UNIQUE NOT NULL,
	-- The following foreign key constraint is not enforced to avoid circular referencing.
	-- FOREIGN KEY (managerNo) REFERENCES Employee,
	managerExtension NUMBER(3)	CHECK (managerExtension BETWEEN 100 AND 999),
	managerCellphone NUMBER(10)
);

CREATE TABLE Employee (
	no		NUMBER(3) 	PRIMARY KEY,
	firstName	VARCHAR2(30)	NOT NULL,
	lastName	VARCHAR2(30)	NOT NULL,
	position	VARCHAR2(30),
	gender		CHAR(1)		CHECK (gender IN ('M', 'F')), 
	birthdate	DATE,
	hireDate	DATE,
	department	VARCHAR2(20)	NOT NULL REFERENCES Department,
	supervisor	NUMBER(3)	REFERENCES Employee,
	CHECK (MONTHS_BETWEEN(hireDate, birthdate)>18*12)
	-- The following table constraint is not enforced yet.
	-- Constraint: "The employee supervision relationship is hierarchical up to three levels."
);

CREATE TABLE Guest (
	no		NUMBER(5) 	PRIMARY KEY,
	firstName	VARCHAR2(10)	NOT NULL,
	lastName	VARCHAR2(10)	NOT NULL,
	birthdate	DATE,
	street		VARCHAR2(20), 
	city		VARCHAR2(10), 
	state		CHAR(2), 
	zip		CHAR(5), 
	phone		NUMBER(10)	
);

CREATE TABLE Member (
	no		NUMBER(5) 	PRIMARY KEY REFERENCES Guest,
	memberLevel	CHAR(1)		CHECK (memberLevel IN ('S', 'G', 'P')),
	totalPoints	NUMBER(10),
	redeemedPoints	NUMBER(10)
);

CREATE TABLE CreditCard (
	no		NUMBER(16) 	PRIMARY KEY,
	type		VARCHAR2(10)	NOT NULL,
	expiration	DATE		NOT NULL
);

CREATE TABLE GuestCreditCard (
	guestNo		NUMBER(5) 	REFERENCES Guest,
	creditCardNo	NUMBER(16) 	REFERENCES CreditCard,
	ownership	VARCHAR2(30),
	PRIMARY KEY (guestNo, ownership)
);

CREATE TABLE Visit (
	confirmation	NUMBER(6)	PRIMARY KEY,
	checkin		DATE		NOT NULL,
	checkout	DATE		NOT NULL,
	status		CHAR(1)		NOT NULL CHECK (status IN ('R', 'C', 'I', 'O')),
	guestNo		NUMBER(5) 	NOT NULL REFERENCES Guest,
	creditCardNo	NUMBER(16) 	NOT NULL REFERENCES CreditCard,
	roomType	VARCHAR2(15) 	NOT NULL REFERENCES RoomType, 
	room		NUMBER(3) 	REFERENCES Room, 
	CHECK (checkOut > checkIn),
	CHECK ((status IN ('R', 'C')) OR (room IS NOT NULL))
	-- The following table constraints are not enforced yet.
	-- Constraint:  A guest cannot make multiple visits on any given day. 
	-- Constraint:  No room can be assigned to multiple guest visits on the same day. 
);

CREATE TABLE VisitRequest (
	confirmation	NUMBER(6)	REFERENCES Visit,
	request		VARCHAR2(100),
	PRIMARY KEY (confirmation, request)
);

CREATE TABLE TransactionType (
	code		NUMBER(3)	PRIMARY KEY CHECK (code BETWEEN 100 AND 999),
	description	VARCHAR2(50),
	direction 	CHAR(1)		NOT NULL CHECK (direction IN ('C', 'D')),
	enteringMethod 	CHAR(1)		NOT NULL CHECK (enteringMethod IN ('A', 'M'))
);

CREATE TABLE Transaction (
	no		NUMBER(7)	PRIMARY KEY CHECK (no BETWEEN 1000000 AND 9999999),
	transactionDate	DATE		NOT NULL,
	amount		NUMBER(7,2)	NOT NULL CHECK (amount > 0),
	memo		VARCHAR2(100),
	transactionType	NUMBER(3)	NOT NULL REFERENCES TransactionType,
	confirmation	NUMBER(6)	NOT NULL REFERENCES Visit,
	enteringEmployee NUMBER(3) 	REFERENCES Employee,
	voidingEmployee	NUMBER(3) 	REFERENCES Employee,
	voidingDate	DATE,
	voidingReason	VARCHAR2(100),
	CHECK ((voidingEmployee IS NULL) OR ((voidingDate IS NOT NULL) AND (voidingReason IS NOT NULL)))
);

-- The following database constraints are not enforced yet.
--Constraint:  There is at least one room of every room type. 
--Constraint:  There is at least one price for every room type. 
--Constraint:  The manager of a department must be an employee in the department. 
--Constraint:  The manager of a department does not have a supervisor. 
--Constraint:  Every credit card belongs to at least one guest. 
--Constraint:  Every guest has at least one credit card. 
--Constraint:  The room number of a visit, if there is one, must be consistent with the room type. 
--Constraint:  The credit card used for a visit must be one of the credit cards of the guest making the visit. 
--Constraint:  The number of reservations for any room type on any day cannot exceed the number of rooms of that room type. 
--Constraint:  If a transaction is of a type that is manually entered, the transaction must be entered by an employee. 
--Constraint:  The date of a transaction must be between the check-in and check-out dates of the visit associated with the transaction. 
--Constraint:  The voiding date of a voided transaction must be between the transaction date and the check-out date of the visit associated with the transaction. 
--Constraint:  The transaction balance of every checked-out visit must be zero. 

-- list all tables
SELECT * from tab;

-- describe the structure of tables.
DESC RoomType 
DESC RoomTypeAmenity 
DESC RoomPrice 
DESC Room 
DESC RoomAmenity 
DESC Department 
DESC Employee 
DESC Guest 
DESC Member 
DESC CreditCard  
DESC GuestCreditCard  
DESC Visit 
DESC VisitRequest 
DESC TransactionType 
DESC Transaction 

-- 2. Enter sample data.
INSERT INTO RoomType 
VALUES (
'Standard', '2 queen beds', 250
);
INSERT INTO RoomType 
VALUES (
'Deluxe', '1 king or 2 queen beds', 350
);
INSERT INTO RoomType 
VALUES (
'Luxury Suite', '2 king beds, 1 crib', 700
);

INSERT INTO Room
VALUES (
201, 2, 'E', 'O', 'Standard'
);
INSERT INTO Room
VALUES (
202, 2, 'E', 'G', 'Standard'
);
INSERT INTO Room
VALUES (
221, 2, 'C', 'C', 'Deluxe'
);
INSERT INTO Room
VALUES (
222, 2, 'C', 'C', 'Deluxe'
);
INSERT INTO Room
VALUES (
241, 2, 'W', 'O', 'Luxury Suite'
);
INSERT INTO Room
VALUES (
243, 2, 'W', 'O', 'Luxury Suite'
);

INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10001, 'Anette', 'Larreau', '25-JAN-1952', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10002, 'Michel', 'Dolan', '13-MAY-1962', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10003, 'Brian', 'Wiggins', '3-JUL-1972', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10004, 'Wendell', 'Thomas', '14-FEB-1985', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10005, 'Salena', 'Dimas', '15-MAR-1957', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10006, 'Terri', 'Smith', '18-JUL-1955', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10007, 'Larry', 'Moxly', '15-AUG-1963', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10008, 'Jim', 'Jones', '31-AUG-1958', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10009, 'Chris', 'Bailey', '16-JAN-1994', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10010, 'Romila', 'Sprangler', '5-FEB-1980', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10011, 'Coco', 'Bronson', '30-APR-1974', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10012, 'Rita', 'Freeman', '26-AUG-1967', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10013, 'Anita', 'Grost', '25-NOV-1981', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10014, 'Steven', 'Nickolsen', '8-JUN-1978', 'IL'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10015, 'Joy', 'Yun', '18-MAY-1952', 'IL'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10016, 'Joanne', 'Danger', '24-JAN-1972', 'WI'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10017, 'Rachel', 'Hamilton', '15-MAY-1954', 'IL'
);
INSERT INTO Guest (no, firstName, lastName, birthdate, state)
VALUES (
10018, 'Nathanael', 'Tyre', '7-JUL-1982', 'IL'
);

INSERT INTO Member
VALUES (
10001, 'S', 5000, 2000
);
INSERT INTO Member
VALUES (
10002, 'S', 9000, 2000
);
INSERT INTO Member
VALUES (
10003, 'G', 5000, 1000
);
INSERT INTO Member
VALUES (
10004, 'P', 7000, 2000
);
INSERT INTO Member
VALUES (
10005, 'P', 4000, 2000
);
INSERT INTO Member
VALUES (
10007, 'S', 5000, 2000
);
INSERT INTO Member
VALUES (
10008, 'G', 8000, 3000
);
INSERT INTO Member
VALUES (
10009, 'S', 5000, 2000
);
INSERT INTO Member
VALUES (
10011, 'P', 7000, 2000
);
INSERT INTO Member
VALUES (
10012, 'S', 5000, 2000
);
INSERT INTO Member
VALUES (
10015, 'S', 5000, 5000
);
INSERT INTO Member
VALUES (
10016, 'S', 5000, 2000
);
INSERT INTO Member
VALUES (
10018, 'P', 4000, 1000
);

INSERT INTO CreditCard
VALUES (
7832465435671626, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
7832465435672345, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
7832465435672342, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
7832465435675244, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
7832465435672322, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
7832465435674564, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
7832465435679238, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
7832465435677324, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
7832465435675626, 'Visa', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435671626, 'Master', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435672345, 'Master', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435672342, 'Master', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435675244, 'Master', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435672322, 'Master', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435674564, 'Master', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435679238, 'Master', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435677324, 'Master', '7-JUL-2029'
);
INSERT INTO CreditCard
VALUES (
3454465435675626, 'Master', '7-JUL-2029'
);

INSERT INTO Visit 
VALUES (
100001, '7-MAR-2023', '17-MAR-2023', 'O', 10001, 7832465435671626, 'Standard', 201
);
INSERT INTO Visit 
VALUES (
100002, '1-OCT-2023', '7-OCT-2023', 'C', 10001, 7832465435671626, 'Standard', null
);
INSERT INTO Visit 
VALUES (
100003, '7-DEC-2023', '17-DEC-2023', 'O', 10001, 7832465435671626, 'Deluxe', 221
);
INSERT INTO Visit 
VALUES (
100004, '10-DEC-2024', '15-DEC-2024', 'R', 10001, 7832465435671626, 'Luxury Suite', null
);
INSERT INTO Visit 
VALUES (
100005, '10-JAN-2023', '12-JAN-2023', 'O', 10003, 7832465435672342, 'Standard', 201
);
INSERT INTO Visit 
VALUES (
100006, '12-DEC-2023', '14-DEC-2023', 'O', 10004, 7832465435675244, 'Luxury Suite', 241
);
INSERT INTO Visit 
VALUES (
100007, '7-DEC-2023', '17-DEC-2023', 'O', 10005, 7832465435672322, 'Deluxe', 221
);
INSERT INTO Visit 
VALUES (
100008, '1-OCT-2024', '15-OCT-2024', 'R', 10005, 7832465435672322, 'Luxury Suite', null
);
INSERT INTO Visit 
VALUES (
100009, '10-DEC-2024', '15-DEC-2024', 'C', 10007, 7832465435679238, 'Luxury Suite', null
);
INSERT INTO Visit 
VALUES (
100010, '7-FEB-2023', '17-FEB-2023', 'O', 10008, 7832465435677324, 'Standard', 201
);
INSERT INTO Visit 
VALUES (
100011, '1-OCT-2023', '7-OCT-2023', 'C', 10008, 7832465435677324, 'Standard', null
);
INSERT INTO Visit 
VALUES (
100012, '7-MAR-2023', '12-MAR-2023', 'O', 10008, 7832465435677324, 'Deluxe', 221
);
INSERT INTO Visit 
VALUES (
100013, '1-DEC-2024', '5-DEC-2024', 'C', 10008, 7832465435677324, 'Luxury Suite', null
);
INSERT INTO Visit 
VALUES (
100014, '17-MAR-2023', '19-MAR-2023', 'O', 10009, 7832465435675626, 'Standard', 201
);
INSERT INTO Visit 
VALUES (
100015, '17-DEC-2023', '19-DEC-2023', 'O', 10009, 7832465435675626, 'Deluxe', 221
);
INSERT INTO Visit 
VALUES (
100016, '17-DEC-2024', '19-DEC-2024', 'R', 10009, 7832465435675626, 'Luxury Suite', null
);
INSERT INTO Visit 
VALUES (
100017, '10-DEC-2023', '15-DEC-2023', 'O', 10010, 7832465435675626, 'Luxury Suite', 243
);
INSERT INTO Visit 
VALUES (
100018, '7-MAR-2023', '17-MAR-2023', 'O', 10011, 3454465435671626, 'Standard', 202
);
INSERT INTO Visit 
VALUES (
100019, '1-OCT-2023', '7-OCT-2023', 'C', 10011, 3454465435671626, 'Standard', null
);
INSERT INTO Visit 
VALUES (
100020, '7-DEC-2023', '17-DEC-2023', 'O', 10011, 3454465435671626, 'Deluxe', 222
);
INSERT INTO Visit 
VALUES (
100021, '19-APR-2023', '21-APR-2023', 'O', 10012, 3454465435671626, 'Standard', 201
);
INSERT INTO Visit 
VALUES (
100022, '10-AUG-2024', '15-AUG-2024', 'R', 10012, 3454465435671626, 'Luxury Suite', null
);
INSERT INTO Visit 
VALUES (
100023, '12-SEP-2024', '15-SEP-2024', 'R', 10014, 3454465435672342, 'Luxury Suite', null
);
INSERT INTO Visit 
VALUES (
100024, '7-SEP-2023', '17-SEP-2023', 'O', 10015, 3454465435675244, 'Deluxe', 221
);
INSERT INTO Visit 
VALUES (
100025, '10-DEC-2023', '15-DEC-2023', 'O', 10015, 3454465435675244, 'Luxury Suite', 241
);
INSERT INTO Visit 
VALUES (
100026, '22-MAR-2023', '24-MAR-2023', 'O', 10016, 3454465435672322, 'Standard', 201
);
INSERT INTO Visit 
VALUES (
100027, '11-OCT-2023', '17-OCT-2023', 'O', 10016, 3454465435672322, 'Standard', 202
);
INSERT INTO Visit 
VALUES (
100028, '17-DEC-2023', '27-DEC-2023', 'O', 10016, 3454465435672322, 'Deluxe', 221
);
INSERT INTO Visit 
VALUES (
100029, '19-DEC-2024', '21-DEC-2024', 'R', 10016, 3454465435672322, 'Luxury Suite', null
);
INSERT INTO Visit 
VALUES (
100030, '2-MAR-2023', '3-MAR-2023', 'O', 10018, 3454465435679238, 'Standard', 201
);
INSERT INTO Visit 
VALUES (
100031, '3-OCT-2023', '4-OCT-2023', 'C', 10018, 3454465435679238, 'Standard', null
);
INSERT INTO Visit 
VALUES (
100032, '2-DEC-2023', '3-DEC-2023', 'O', 10018, 3454465435679238, 'Deluxe', 221
);
INSERT INTO Visit 
VALUES (
100033, '12-DEC-2023', '15-DEC-2023', 'O', 10018, 3454465435679238, 'Luxury Suite', 243
);

-- commit the transaction.
COMMIT;

-- display the data
SELECT * FROM RoomType;
SELECT * FROM Room;
SELECT no, firstName, lastName, birthdate, state FROM Guest;
SELECT * FROM Member;
Column no format a16
SELECT * FROM CreditCard;
Column creditCardNo format a16
SELECT * FROM Visit;

-- 3. Sample queries
-- 3.1 Get the guest number, first name, last name, and birthdate of every guest.

SELECT	no, firstName, lastName, birthDate
FROM	Guest;

-- 3.2 Get the guest number, name (first name plus last name), and age of every guest from Wisconsin.

SELECT	no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age
FROM	Guest
WHERE	state = 'WI';

-- 3.3 Get the guest number, name, and age of every member from Wisconsin.

SELECT	g.no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age
FROM	Guest g, Member b
WHERE	g.no = b.no
	AND state = 'WI';

-- 3.4 Get the guest number, name, and age of every member from Wisconsin who has stayed (including reserved visits but excluding canceled visits) in a luxury suite.

SELECT	UNIQUE g.no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age
FROM	Guest g, Member b, Visit v
WHERE	g.no = b.no
	AND g.no = v.guestNo
	AND state = 'WI'
	AND roomType = 'Luxury Suite'
	AND status <> 'C'
ORDER BY g.no;

-- 3.5 Get the following about every member from Wisconsin who has stayed in a luxury suite: guest number, name, age, and visits (check in, check out, and room type). Include visits of other room types too.

SELECT	g.no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age, checkIn, checkOut, roomType
FROM	Guest g, Visit v
WHERE	g.no = v.guestNo
	AND status <> 'C'
	AND g.no IN
	(
	SELECT	g.no
	FROM	Guest g, Member b, Visit v
	WHERE	g.no = b.no
		AND g.no = v.guestNo
		AND state = 'WI'
		AND roomType = 'Luxury Suite'
		AND status <> 'C'
	);

-- 3.6 Get the following about every member from Wisconsin who has stayed in a luxury suite: guest number, name, age, number of visits (including visits of other room types too), and total number of nights, and average number of nights per visit.

SELECT	g.no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age, COUNT(confirmation) AS visits, SUM(checkOut - checkIn) AS totalNights, SUM(checkOut - checkIn)/COUNT(confirmation) AS averageNights
FROM	Guest g, Visit v
WHERE	g.no = v.guestNo
	AND status <> 'C'
	AND g.no IN
	(
	SELECT	g.no
	FROM	Guest g, Member b, Visit v
	WHERE	g.no = b.no
		AND g.no = v.guestNo
		AND state = 'WI'
		AND roomType = 'Luxury Suite'
		AND status <> 'C'
	)
GROUP BY g.no, firstName, lastName, birthDate
ORDER BY g.no;

-- 3.7 Get the following about every repeating member (i.e., has visited CPH multiple times) from Wisconsin: guest number, name, age, number of visits, and total number of nights, and average number of nights per visit.

SELECT	g.no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age, COUNT(confirmation) AS visits, SUM(checkOut - checkIn) AS totalNights, SUM(checkOut - checkIn)/COUNT(confirmation) AS averageNights
FROM	Guest g, Member b, Visit v
WHERE	g.no = b.no
	AND g.no = v.guestNo
	AND state = 'WI'
	AND status <> 'C'
GROUP BY g.no, firstName, lastName, birthDate
HAVING   COUNT(confirmation)>1
ORDER BY g.no;

-- 3.8 Get the following about every repeating member from Wisconsin who has not stayed in a luxury suite yet: guest number, name, age, number of visits, and total number of nights, and average number of nights per visit.

SELECT	g.no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age, COUNT(confirmation) AS visits, SUM(checkOut - checkIn) AS totalNights, SUM(checkOut - checkIn)/COUNT(confirmation) AS averageNights
FROM	Guest g, Member b, Visit v
WHERE	g.no = b.no
	AND g.no = v.guestNo
	AND state = 'WI'
	AND status <> 'C'
GROUP BY g.no, firstName, lastName, birthDate
HAVING   COUNT(confirmation)>1
	MINUS
SELECT	g.no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age, COUNT(confirmation) AS visits, SUM(checkOut - checkIn) AS totalNights, SUM(checkOut - checkIn)/COUNT(confirmation) AS averageNights
FROM	Guest g, Visit v
WHERE	g.no = v.guestNo
	AND status <> 'C'
	AND g.no IN
	(
	SELECT	g.no
	FROM	Guest g, Member b, Visit v
	WHERE	g.no = b.no
		AND g.no = v.guestNo
		AND state = 'WI'
		AND roomType = 'Luxury Suite'
		AND status <> 'C'
	)
GROUP BY g.no, firstName, lastName, birthDate;

-- 3.9 Get the guest number, name, and age of every guest who has stayed in all types of rooms. (Hint: This query involves the Division operation in relational algebra, but is notoriously difficult to write in SQL. Consider using sub-queries. Restate the query as  Find every guest, such that there does not exist a room type that the guest has not stayed in ).

SELECT	no, firstName || ' ' || lastName AS name, FLOOR(MONTHS_BETWEEN(SYSDATE, birthDate)/12) AS age
FROM	Guest g
WHERE	NOT EXISTS
	(
	SELECT	name
	FROM	RoomType
	MINUS
	SELECT	roomType
	FROM	Visit v
	WHERE	v.guestNo = g.no
		AND status <> 'C'
	);

-- 3.10 Get the confirmation, check in, check out, room type, and room information (room number, wing, and view, if a room has been allocated) of every guest visit.

SELECT	confirmation, checkIn, checkOut, v.roomType, room, wing, roomView
FROM	Visit v
	LEFT OUTER JOIN 
	Room r
	ON v.room = r.no
WHERE	status <> 'C'
ORDER BY confirmation;

SELECT	confirmation, checkIn, checkOut, v.roomType, room, wing, roomView
FROM	Visit v, Room r
WHERE	v.room = r.no
	AND status <> 'C'
UNION
SELECT	confirmation, checkIn, checkOut, roomType, NULL AS room, NULL AS wing, NULL AS roomView
FROM	Visit v
WHERE	room IS NULL
	AND status <> 'C';
