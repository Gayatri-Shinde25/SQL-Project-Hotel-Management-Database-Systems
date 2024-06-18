
SET ECHO ON
--Data and Info  Management
--Gayatri Shinde
--UserName GSSHINDE
--Assignment 4- I have not used professor's last solution rather have used mine with corrected version. Attaching both files

 -- Query to determine the level of the supervisor
CREATE OR REPLACE TRIGGER CheckSupervisionLevel
BEFORE INSERT ON Employee
FOR EACH ROW
DECLARE
    flag	NUMBER(1);
    level	NUMBER(1);
    managerID	Employee.supervisor%TYPE;
BEGIN
    -- The supervision relationship is hierarchical up to three levels.
    managerID := :NEW.supervisor;
    IF managerID IS NULL THEN
	RETURN;
    END IF;

    SELECT COUNT(*) INTO flag
    FROM   Employee
    WHERE  empNo = managerID;
    IF flag < 1 THEN
	RETURN;
    END IF;
    
    level := 1;
    WHILE level <= 3 AND managerID IS NOT NULL LOOP
	SELECT supervisor INTO managerID
	FROM   Employee
	WHERE  empNo = managerID;
	level := level + 1;
    END LOOP;

    IF level > 3 THEN
	RAISE_APPLICATION_ERROR('-20003', 
	'Integrity Constraint Violated: The supervision relationship is hierarchical up to three levels!');
    END IF;
END;
/


SHOW ERROR
--SELECT line, text FROM user_source WHERE name = UPPER('SupervisionConstraint');


-- test the trigger
INSERT INTO Department VALUES ('Front Desk', 221, 4149230011, 101, 4147652233, 222);

INSERT INTO Department VALUES ('Restaurant', 223, 4149230012, 111, 4148876677, 224);

INSERT INTO Employee (empNo, firstName, lastName, gender, department, supervisor)
VALUES (101, 'Adam', 'Baker', 'M', 'Front Desk', 102);


INSERT INTO Employee (empNo, firstName, lastName, gender, department, supervisor)
VALUES (101, 'Adam', 'Baker', 'M', 'Front Desk', null);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (102, 'Steve', 'Dickens', 'M', 'Front Desk', 101);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (103, 'Alana', 'Carlyle', 'F', 'Front Desk', 102);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (104, 'Bill', 'Lee', 'M', 'Front Desk', 103);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (104, 'Bill', 'Lee', 'M', 'Front Desk', 102);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (111, 'Daniel', 'Lincoln', 'M', 'Restaurant', 112);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (111, 'Daniel', 'Lincoln', 'M', 'Restaurant', null);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (112, 'Sam', 'Gerbstedt', 'M', 'Restaurant', 111);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (113, 'Lina', 'Liu', 'F', 'Restaurant', 112);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (114, 'Bob', 'Johnstone', 'M', 'Restaurant', 113);

INSERT INTO Employee (empno, firstName, lastName, gender, department, supervisor)
VALUES (114, 'Bob', 'Johnstone', 'M', 'Restaurant', null);

Select * from Employee;


-- Calculate total amount spent by the guest during the visit
CREATE OR REPLACE FUNCTION calculate_transaction_balance(visit_confirmation IN INT)
RETURN DECIMAL
IS
    v_total_amount DECIMAL(10,2) := 0;
BEGIN
    -- Check if the confirmation number exists in the Visit table
    SELECT COUNT(*)
    INTO v_total_amount
    FROM Visit
    WHERE confirmation = visit_confirmation;

    IF v_total_amount = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Confirmation number does not exist.');
    END IF;

    -- Check if transactions exist for the given confirmation number
    SELECT COALESCE(SUM(CASE WHEN transactionType IN (201, 202) THEN -amount ELSE amount END), 0)
    INTO v_total_amount
    FROM Transaction
    WHERE confirmation = visit_confirmation
    AND (voidingEmployee IS NULL OR voidingDate IS NULL OR voidingReason IS NULL);

    RETURN v_total_amount;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0; -- Return 0 if no transactions found for the visit
END;
/

SHOW ERRORS
--SELECT line, text FROM user_source WHERE name = UPPER('Balance');


-- Use the function in queries
INSERT INTO TransactionType
VALUES (101, 'Room charge posted automatically every night', 'C', 'A');

INSERT INTO TransactionType
VALUES (102, 'Restaurant bill signed to room', 'C', 'M');

INSERT INTO TransactionType
VALUES (201, 'Credit card payment auto posted at check out', 'D', 'A');

INSERT INTO TransactionType
VALUES (202, 'Credit card payment manually entered', 'D', 'M');

INSERT INTO Visit 
VALUES (100034, '11-OCT-2023', '7-JAN-2024', 'I', 10001, 7832465435671626, 'Standard', 201);

INSERT INTO Visit 
VALUES (100035, '11-OCT-2023', '6-JAN-2024', 'I', 10002, 7832465435672345, 'Standard', 202);

INSERT INTO Transaction
VALUES (1000035, '4-JAN-2024', 95, 'Room charge', 101, 100034, null, null, null, null);

INSERT INTO Transaction
VALUES (1000036, '5-JAN-2024', 15, 'Breakfast', 102, 100034, 113, null, null, null);

INSERT INTO Transaction
VALUES (1000037, '5-JAN-2024', 35, 'Lunch', 102, 100034, 114, 114, '6-JAN-2024', 'Paid cash at restaurant');

INSERT INTO Transaction
VALUES (1000038, '5-JAN-2024', 95, 'Room charge', 101, 100034, null, null, null, null);

INSERT INTO Transaction
VALUES (1000039, '5-JAN-2024', 95, 'Room charge', 101, 100035, null, null, null, null);

INSERT INTO Transaction
VALUES (1000040, '6-JAN-2024', 95, 'Credit card payment', 202, 100035, 103, null, null, null);


SELECT calculate_transaction_balance(100001) FROM DUAL;
SELECT calculate_transaction_balance(100034) FROM DUAL;
SELECT calculate_transaction_balance(100035) FROM DUAL;
SELECT calculate_transaction_balance(100036) FROM DUAL;

SELECT Confirmation, checkIn, checkOut, status, calculate_transaction_balance(confirmation)
FROM Visit
WHERE guestNo < 10003;


-- Procedure to check out a guest visit
CREATE OR REPLACE PROCEDURE checkout_guest_visit(visit_confirmation IN INT)
IS
    v_transaction_balance DECIMAL(10,2);
    v_checked_in_status CHAR(1);
    tNo Transaction.transactionNo%type;
BEGIN
    -- Check if the guest is currently checked in
    SELECT status INTO v_checked_in_status
    FROM Visit
    WHERE confirmation = visit_confirmation;

    -- If guest is not currently checked in, exit procedure with message
    IF v_checked_in_status <> 'I' THEN
        RAISE_APPLICATION_ERROR(-20004, 'The guest is not currently checked in!');
        RETURN;
    ELSE

        -- Calculate transaction balance for the visit
        SELECT calculate_transaction_balance(visit_confirmation)
        INTO v_transaction_balance
        FROM dual;
    
        -- If transaction balance is not zero, post automatic credit card payment
        IF v_transaction_balance <> 0 THEN
            select max(transactionNo) + 1 into tNo
            from Transaction;
        
            INSERT INTO Transaction (transactionNo, transactionDate, amount, memo,  transactionType, confirmation)
            VALUES (tNo, SYSDATE, v_transaction_balance,'Automatic credit card payment', 201, visit_confirmation);
        END IF;

        -- Update status of the visit to "O" and check-out date to today's date
        UPDATE Visit
        SET status = 'O', checkOut = SYSDATE
        WHERE confirmation = visit_confirmation;
       
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Confirmation number does not exists!');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

SHOW ERROR
--SELECT line, text FROM user_source WHERE name = UPPER('CheckOut');

-- execute the procedure
EXECUTE checkout_guest_visit(100001);
EXECUTE checkout_guest_visit(100034);
EXECUTE checkout_guest_visit(100035);
EXECUTE checkout_guest_visit(100036);

SELECT Confirmation, checkIn, checkOut, status, calculate_transaction_balance(confirmation)
FROM Visit
WHERE guestNo < 10003;

SELECT * FROM Transaction;

COMMIT;

