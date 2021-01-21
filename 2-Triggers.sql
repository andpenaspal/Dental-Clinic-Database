
USE DentalClinicDB;

 -- Triggers:

-- Trigger Set Instalments
	-- When inserting a Bill, will create statements following the payment plan

DELIMITER $$
CREATE TRIGGER Set_Instalments AFTER INSERT ON BILL FOR EACH ROW 
BEGIN
	DECLARE subTotal DECIMAL(6,2);
	DECLARE counter int DEFAULT 1;
	-- Total of each instalment: Total of the bill / number of Payments
	SET subTotal = (NEW.total/NEW.PaymentPlan);
	-- Recursion to insert the instalments, as many as payments needed
	WHILE counter <= NEW.PaymentPlan DO 
		-- Insert into Instalments
			-- Date: One month betwwen instalments.
				-- conunter - 1: to start adding 0 months, it is, same date as Bill. If only one instalment, that will be its date
					-- if more than one instalment, that would be the date of the first, as counter goes higher, adding month too
		INSERT INTO Instalment VALUES (NULL, (SELECT (ADDDATE(NEW.BillDate, INTERVAL (counter - 1) MONTH))), subTotal, FALSE, NEW.BillNo);
		-- Add one to the base case situation
		SET counter = counter + 1;
	END WHILE;
END
$$


-- ERROR: 
	-- This first Trigger is the one causing the fatal ERROR. It works if inserted from PHPMyAdmin.
	-- UPDATE: Works without populating the DB in the same file. MANY THANKS!!

-- Catch_Defaulter:
 /* Explanation: Trigger Checks for defaulters even if the attribute hasn't updated. Error message if Defaulter caught.
 	Error doesn't allow the update of the Defaulter attribute (I guess the trigger is understood as a transaction and if it gives an 
	error all rolles back). Technically I don't have to SET Defaulter with new appointments, 
	but there's no other associated event. Good solution would be to make some kind of periodical check, don't think SQL allows that. 
	Best solution would be a INSTEAD OF Trigger but MySQL doesn't support it. */


CREATE TRIGGER Catch_Defaulters BEFORE INSERT ON Appointment FOR EACH ROW 
BEGIN
-- Defaulters can be for two reasons:
	-- Too old (1 month) Instalment NOT paid
	-- Too big but not that old (10 days) Instalment NO paid

	-- Variables to use later
	DECLARE checkDefaulter boolean;
	DECLARE limitDateToPay date;
	DECLARE tooMuchDate date;

-- Check too old statements
	-- Add 1 month to oldest Instalment not paid for this Client
		-- Add one month
	SET limitDateToPay = (SELECT ADDDATE((SELECT MIN(instDate)
		-- Select correct client
		FROM instalment, bill, appointment
		WHERE instalment.BillNo=Bill.BillNo
		AND Bill.AppointmentNo=Appointment.appointmentNo
		AND Appointment.ClientNo=NEW.ClientNo
		-- Select Instalments NOT already paid
		AND instalmentNo NOT IN (
				SELECT InstalmentNo FROM Payment WHERE ClientNo = new.ClientNo)) 
	,INTERVAL 1 MONTH));
	-- Check if the Date limit to pay NOT paid Instalents is before curent date
	IF CURDATE() > limitDateToPay THEN
		-- Updates the table oneonly temporarily, but enough for our IF statement later
		UPDATE client SET defaulter = true WHERE ClientNo = NEW.ClientNo;
	END IF;

-- Check Too big but not that old Not paid instalments
	-- Check the dates of the NOT PAID Instalments for this client
		-- Check the oldest NOT PAID Instalment bigger than the limit (99.99)
			-- Store them in a TEMPORARY table to avoid multiple rows error
				-- (If two Instalment from same client with same date and same total. Difficult but possible)
		-- Create temporary table with the MIN Dates
	CREATE TEMPORARY TABLE IF NOT EXISTS possible_Dates AS (SELECT MIN(instDate)
		-- Look for correct client
		FROM instalment, bill, appointment
		WHERE instalment.BillNo=Bill.BillNo
		AND Bill.AppointmentNo=Appointment.appointmentNo
		AND Appointment.ClientNo=NEW.ClientNo
		-- With the big Total
		AND Instalment.total > 99.99
		-- Instalment not paid
		AND instalmentNo NOT IN (
				SELECT InstalmentNo FROM Payment WHERE ClientNo = new.ClientNo));
	-- Set the date adding 10 days to the oldest not paid instalment bigger than the limit
		-- Distinct in case of two same dates with same client and bigger amount
	SET tooMuchDate = (SELECT ADDDATE((SELECT DISTINCT * FROM possible_Dates), INTERVAL 10 DAY));
	-- Check if the date of the not that old but big not paid instalment is older than 10 days
	IF (CURDATE() > tooMuchDate) THEN
		UPDATE client SET defaulter = true WHERE ClientNo = NEW.ClientNo;
	END IF;
	-- Set if any of above happened
	SET checkDefaulter = (SELECT Defaulter FROM client WHERE ClientNo = NEW.ClientNo);
	-- Check if any of the above happened
		-- If so, sent a message saying it and abort mission
	IF checkDefaulter = TRUE THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Defaulter Client, No new Appointments allowed until the debt has been cleared';
	END IF;
	-- Drop the temporary table (in case of different situations same sesion)
	DROP TEMPORARY TABLE IF EXISTS possible_Dates;
-- If nothing of this happens, INSERT without problems
END
$$


-- Payments 
	-- Look for the proper instalment. Avoid having to look manually for instalments not paid and the correct instalment


CREATE TRIGGER look_For_Instalment BEFORE INSERT ON PAYMENT FOR EACH ROW
BEGIN
	DECLARE instalmentDate date;
	DECLARE correct_InstalmentNo int DEFAULT NULL;
	-- Look for Instalments not date (Can't assume is paying the oldest)
	-- Teporary table: There may be more than one instalment not paid
	CREATE TEMPORARY TABLE IF NOT EXISTS possible_Inst AS (
		SELECT instalmentNO FROM Instalment, Bill, Appointment WHERE
		-- Look for correct Client
		Instalment.billNo=bill.billNo 
		AND bill.appointmentNo=Appointment.appointmentNo 
		AND Appointment.clientNo=NEW.clientNo
		-- Instalment not paid
		AND InstalmentNo NOT IN (
			SELECT instalmentNo FROM Payment WHERE ClientNo = new.ClientNo));
	-- Select the date of the instalments from before
		-- Distinct because there could be more tha one with same date (Avoid error of multiple row). 
			-- MIN: If there's 2 instalments not paid with same total let's assume is the oldest the one that needs to be paid
	SET instalmentDate = (SELECT DISTINCT MIN(instDate)
		FROM instalment
		-- Same total (ignore instalments not paid with different amount as the payment)
		WHERE NEW.total = total 
		-- And in the not paid (Temporary table)
		AND instalmentNo IN (
			SELECT * FROM possible_Inst));
	-- Same as above but to get the InstalmentNo
		-- Above could be avoided but for readibility
	SET correct_InstalmentNo = (SELECT MIN(InstalmentNo) 
	FROM instalment 
	-- Date as selected before
	WHERE InstDate = instalmentDate 
	AND instalmentNo IN (
		SELECT * FROM possible_Inst));
	-- Update the NEW value inserted
	SET NEW.InstalmentNO = correct_InstalmentNo;
	-- If the Total paid is not the same as one of the instalments not paid, send error
	IF NEW.Total NOT IN (SELECT total FROM Instalment WHERE instalmentNO IN (SELECT * FROM possible_Inst)) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Total not found in Instalment table';
	END IF;
	DROP TEMPORARY TABLE IF EXISTS possible_Inst;
END
$$


-- Late Cancelation 
	-- If its a Late cancelation (Attribute updated to LateCancelation), create a Bill automatically
	-- If its late or not has to be checked manually
		-- Would be nice to check it automatically, but MySQL doesn't support INSTEAD OF DELETE Trigger, and the recepcionist would
			-- delete the appointment...


CREATE TRIGGER `Bill_Late_Cancelation` AFTER UPDATE ON `appointment` FOR EACH ROW 
BEGIN
	IF NEW.LateCancelation = TRUE THEN
		-- Create Bill
		INSERT INTO Bill VALUES (NULL, OLD.AppDate, 20, 1, OLD.AppointmentNo);
		-- Delete entry from AppointmentDetails (To not show it in Next Week appointments)
		DELETE FROM appointmentdetails WHERE AppointmentNo=OLD.appointmentNO;
	END IF;
END
$$
DELIMITER ;
