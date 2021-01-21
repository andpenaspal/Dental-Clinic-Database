
USE DentalClinicDB;

-- POPULATE TABLES
-- Examples of Data to test the DB: INSERT, UPDATE, DELETE & CREATE

-- Client
	-- DEFAULTERS: 6, 7, 9, 16
INSERT INTO client VALUES 
	(NULL, 'Andres', 'Penas', '1991-03-17', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'Patrick', 'Smith', '1995-03-17', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'John', 'Carter', '1981-03-21', '123 Fake Street, Cork, Ireland', FALSE), 
	(NULL, 'Robert', 'Smith', '1971-02-14', '123 Fake Street, Dublin, Ireland', FALSE), 
	(NULL, 'Eoin', 'Jordan', '1984-03-25', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'Emma', 'Smith', '1990-05-28', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'Cora', 'Gasol', '1977-03-28', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'Melissa', 'Smith', '1969-08-22', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'Peter', 'Garnet', '1992-04-04', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'Lisa', 'Smith', '1981-11-01', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'Laura', 'James', '1987-12-07', '123 Fake Street, Galway, Ireland', FALSE), 
	(NULL, 'Sean', 'Smith', '1991-04-17', '123 Fake Street, Galway, Ireland', FALSE),
	(NULL, 'Jack', 'Sparrow', '1990-06-01', '123 Fake Street, Galway, Ireland', FALSE),
    (NULL, 'Socrates', 'Daemon', '1990-07-01', '123 Fake Street, Galway, Ireland', FALSE);

-- Appointment
INSERT INTO appointment VALUES 
	-- Old 1
	(NULL, '2020-03-14', '10:00:00', TRUE, FALSE, 1), 
	(NULL, '2020-03-14', '10:30:00', TRUE, FALSE, 2), 
	(NULL, '2020-03-14', '11:00:00', TRUE, FALSE, 3), 
	(NULL, '2020-03-14', '12:00:00', TRUE, FALSE, 4), 
	(NULL, '2020-03-20', '10:00:00', TRUE, FALSE, 5), 
	(NULL, '2020-03-20', '11:00:00', TRUE, FALSE, 6), 
	(NULL, '2020-03-20', '11:30:00', TRUE, FALSE, 7), 
	(NULL, '2020-03-20', '10:30:00', TRUE, FALSE, 8), 
	(NULL, '2020-03-20', '16:00:00', TRUE, FALSE, 9), 
	(NULL, '2020-03-25', '10:00:00', TRUE, FALSE, 10), 
	(NULL, '2020-03-25', '10:30:00', TRUE, FALSE, 11), 
	(NULL, '2020-03-25', '11:00:00', TRUE, FALSE, 12), 
	
	-- Old 2
	(NULL, '2020-03-31', NULL, TRUE, FALSE, 1), 
	(NULL, '2020-03-28', '10:00:00', TRUE, FALSE, 3), 
	(NULL, '2020-03-27', NULL, TRUE, FALSE, 12), 
	(NULL, '2020-04-15', '10:00:00', TRUE, FALSE, 1),

	-- Defaulter

	(NULL, ADDDATE(CURDATE(), INTERVAL -32 DAY), '16:30:00', TRUE, FALSE, 13),

	-- 3 days ago

	(NULL, ADDDATE(CURDATE(), INTERVAL -3 DAY), '10:00:00', TRUE, FALSE, 5),
	(NULL, ADDDATE(CURDATE(), INTERVAL -3 DAY), '10:30:00', TRUE, FALSE, 7),
	(NULL, ADDDATE(CURDATE(), INTERVAL -3 DAY), '11:30:00', TRUE, FALSE, 10),

	-- Today's

	(NULL, CURDATE(), '10:00:00', TRUE, FALSE, 1),
	(NULL, CURDATE(), '10:30:00', TRUE, FALSE, 2),
	(NULL, CURDATE(), '11:00:00', TRUE, FALSE, 3), 
	(NULL, CURDATE(), NULL, TRUE, TRUE, 4),

	-- Future
	(NULL, '2020-06-14', '10:00:00', FALSE, FALSE, 2), 
	(NULL, '2020-06-12', '10:00:00', FALSE, FALSE, 3), 
	(NULL, '2020-06-14', '11:00:00', FALSE, FALSE, 4), 
	(NULL, '2020-06-12', '11:00:00', FALSE, FALSE, 8), 
	(NULL, '2020-06-14', '12:00:00', FALSE, FALSE, 11);

-- Update Client (Avoid Trigger in INSERT ON Appointment for defaulters and old appointments)
UPDATE Client SET Defaulter=TRUE WHERE clientNo IN (6, 7, 9, 16);

-- Poject specification: DELETE Query
DELETE FROM Client WHERE clientNo=14;

-- Treatment
INSERT INTO treatment VALUES 
	('Examination', 50), 
	('Cleaning', 100), 
	('X-Ray', 150), 
	('Filling', 70), 
	('Denture', 500), 
	('Denture FollowUp', 0), 
	('Bridge', 250), 
	('Crown', 50), 
	('Veneers', 0), 
	('Whitening', 0),
	('FollowUp', 0) ;

-- Specialist
INSERT INTO specialist VALUES 
	('Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland', '085123456'),
	('McCarthy''s Dental Clinic', '456 Fake Street, Cork City, Cork, Ireland', '085456789'),
	('Casserly''s Dental Clinic', '789 Fake Street, Cork City, Cork, Ireland', '085876543');

-- Specialization
INSERT INTO specialization VALUES 
	('Examination', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
	('Cleaning', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
	('X-ray', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
	('Filling', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
	('Denture', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
	('Denture FollowUp', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
	('Bridge', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
	('Crown', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
	('Veneers', 'McCarthy''s Dental Clinic', '456 Fake Street, Cork City, Cork, Ireland'),
	('Whitening', 'Casserly''s Dental Clinic', '789 Fake Street, Cork City, Cork, Ireland'),
	('FollowUp', 'Mulcahy''s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland');

-- Appointment Details
INSERT INTO appointmentDetails VALUES 
	('Examination', 1, 'Problems, sent for Veneers', 'Refer for Veneers'),  
	('Crown', 2, 'All fine', 'Not needed'), 
	('Examination', 3, 'Discused Denture Options. Will think about it', 'Not needed'), 
	('X-ray', 4, 'All fine, will see in few weeks how it is', 'Few weeks Examination'), 
	('Examination', 5, 'All fine', 'Not needed'), 
	('Crown', 6, 'All fine', 'Not needed'), 
	('Cleaning', 7, 'All fine', 'Not needed'), 
	('Filling', 8, 'All fine', 'Few weeks'), 
	('Denture', 9, 'All fine', 'Few weeks Follow up'), 
	('Examination', 10, 'All fine', 'Not needed'),
	('Denture', 11, 'All fine', 'Few weeks followUp'), 
	('Bridge', 12, 'All fine', 'Refer for whitening'),

	('Veneers', 13, 'Veneers done. Documents received', 'Not needed'),
	('Denture', 15, 'All fine', 'Few Weeks'),
	('Whitening', 14, 'All fine', 'Not needed'),
	('FollowUp', 16, 'All fine', 'Not needed'),

	('Examination', 17, 'Allfine', 'Not needed'),
	 
	('FollowUp', 18, 'Allfine', 'Not needed'),
	('Examination', 19, 'Allfine', 'Not needed'),
	('Examination', 20, 'Allfine', 'Not needed'),

	('FollowUp', 21, NULL, NULL),
	('Examination', 22, NULL, NULL),
	('Examination', 23, NULL, NULL),
	
	('FollowUp', 25, NULL, NULL), 
	('FollowUp', 26, NULL, NULL), 
	('Examination', 27, NULL, NULL), 
	('FollowUp', 28, NULL, NULL), 
	('Denture FollowUp', 29, NULL, NULL);

-- Bill 
INSERT INTO Bill VALUES 
	(NULL, '2020-03-14', 50, 1, 1), 
	(NULL, '2020-03-14', 50, 1, 2), 
	(NULL, '2020-03-14', 50, 1, 3), 
	(NULL, '2020-03-14', 150, 2, 4), 
	(NULL, '2020-03-20', 50, 1, 5), 
	(NULL, '2020-03-20', 50, 1, 6), 
	(NULL, '2020-03-20', 100, 1, 7), 
	(NULL, '2020-03-20', 70, 1, 8), 
	(NULL, '2020-03-20', 500, 6, 9),
	(NULL, '2020-03-25', 50, 1, 10), 
	(NULL, '2020-03-25', 500, 6, 11), 
	(NULL, '2020-03-25', 250, 3, 12), 
	
	(NULL, '2020-03-28', 500, 6, 14),

	(NULL, ADDDATE(CURDATE(), INTERVAL -32 DAY), 50, 1, 17),

	(NULL, ADDDATE(CURDATE(), INTERVAL -3 DAY), 50, 1, 19),
	(NULL, ADDDATE(CURDATE(), INTERVAL -3 DAY), 50, 1, 20),

	(NULL, CURDATE(), 20, 1, 24);

-- Instalment
-- Not needed, Trigger does it

-- Payment
INSERT INTO payment VALUES 
	-- First round of app: Defaulter: ClientNo 6
	(NULL, 50, '2020-03-18', "Cash", 1, NULL),
	(NULL, 50, '2020-03-19', "Cash", 2, NULL),
	(NULL, 50, '2020-03-20', "Credit Card", 3, NULL),
	(NULL, 75, '2020-03-19', "Cash", 4, NULL),
	(NULL, 50, '2020-03-21', "Credit Card", 5, NULL),
	(NULL, 100, '2020-03-23', "Cash", 7, NULL),
	(NULL, 70, '2020-03-25', "Cash", 8, NULL),
	(NULL, 83.33, '2020-03-24', "Credit Card", 9, NULL),
	(NULL, 50, '2020-03-26', "Cash", 10, NULL),
	(NULL, 83.33, '2020-03-29', "Cash", 11, NULL),
	(NULL, 83.33, '2020-03-30', "Cash", 12, NULL),
	
	-- First round payment plan. Defaulter: 9
	(NULL, 75, '2020-04-16', "Credit Card", 4, NULL),
	(NULL, 83.33, '2020-04-25', "Credit Card", 11, NULL),
	(NULL, 83.33, '2020-04-30', "Cash", 12, NULL),

	-- Second round of app
	(NULL, 83.33, '2020-04-05', "Credit Card", 3, NULL)
	;

-- TelfNo
INSERT INTO telfno VALUES 
	(1, 0891234567), 
	(1, 0891230000), 
	(2, 0891234567), 
	(3, 0891234567), 
	(4, 0891234567);

-- Views

-- Medical History
	-- View to see the medical history of the clients, showing relevant information from the past

CREATE VIEW MedicalHistory AS SELECT appointment.ClientNo, appointment.appDate, appointmentdetails.treatmentname, 
	appointmentdetails.treatmentdetails FROM appointment, appointmentdetails WHERE appointment.latecancelation = FALSE
	AND appointment.appDate <= CURDATE() AND Appointment.appointmentNo=AppointmentDetails.appointmentNo 
	AND Appointment.AppDate <= CURDATE();

-- Next Week Appointments
	-- View to check next wekk's appointments, and remaind them if necessary
	-- Bussines rule: checked on Thursday, so show the next 10 days: count Friday and weekend

CREATE VIEW NextWeek_Appoitments AS SELECT clientNo, AppDate, AppHour, remainded FROM appointment 
	WHERE AppHour IS NOT NULL AND AppDate BETWEEN CURDATE() AND ADDDATE(CURDATE(), INTERVAL 10 DAY);

-- Next Week Treatments
	-- View to check the next week's treatments, for the doctor

CREATE VIEW NextWeek_Treatmens AS SELECT appointment.ClientNo, appointment.AppDate, appointment.AppHour, 
	appointmentDetails.TreatmentName FROM appointment, appointmentdetails 
	WHERE appointment.appointmentNo = appointmentdetails.appointmentNo AND appointment.AppDate 
	BETWEEN CURDATE() AND ADDDATE(CURDATE(), INTERVAL 10 DAY);

-- Send Instalments 
	-- Treatments from last week. Bussiness rule, receptionist does it every week

CREATE VIEW Send_Instalments AS SELECT appointment.ClientNo, instalment.instalmentNO, instalment.instsent FROM appointment, instalment, 
	Bill WHERE instalment.billNo = Bill.billNo AND Bill.AppointmentNo = appointment.appointmentNo 
	AND instalment.instDate BETWEEN ADDDATE(CURDATE(), INTERVAL -10 DAY) AND CURDATE();

-- Today's appointment FOLLOW UP
	-- View to give the receptionist information for the Bill and Next appointments for the client
	-- Checked every day for this day's clients

CREATE  VIEW  FollowUp AS SELECT appointment.ClientNo, appointment.appDate, appointment.appHour, appointmentdetails.treatmentname,
	treatment.treatmentprice, appointmentdetails.followup FROM appointment, appointmentdetails, treatment WHERE
	appointment.appointmentNo=appointmentdetails.appointmentNo AND treatment.treatmentname=appointmentdetails.treatmentname 
	AND AppDate = CURDATE();


-- Check Defaulters
	-- View to check NEW defaulters

CREATE VIEW Check_Defaulters AS 
	-- MIN: because the oldest is the relevant
	SELECT MIN(instDate) AS instalmentDate, Appointment.clientNo, instalment.instalmentNO, instalment.total 
	FROM client, instalment, appointment, bill WHERE 
	-- Bussiness rules for Defaulters. One or the another
		-- Instalment older than a month
		-- Instalment older than 10 days (not specified, but to put something) and amount bigger than 99.99 (same)
	(CURDATE() > (SELECT ADDDATE(MIN(instDate), INTERVAL 1 MONTH)) OR 
	((CURDATE() > (SELECT ADDDATE(MIN(instDate), INTERVAL 10 DAY))) AND Instalment.total > 99.99)) 
	-- Just show the hypothetcal new ones
	AND appointment.clientNo=client.clientNo
	AND client.defaulter=FALSE 
	-- Show ClientNo: easier to update
	AND Appointment.appointmentNo=bill.appointmentNo 
	AND bill.BillNo=Instalment.billNo 
	-- Instalments not paid
	AND instalment.InstalmentNo NOT IN ( 
		SELECT instalmentNo FROM payment)
	GROUP BY Appointment.clientNo;

-- LateCancelations
    -- View the clients with late cancelations
    
CREATE VIEW LateCancelations AS SELECT clientNo, AppDate, LateCancelation FROM Appointment WHERE LateCancelation=TRUE;
