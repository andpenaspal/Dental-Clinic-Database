-- Introductory commands (Thanks to "Soren Spangsberg Jorgensen" - YouTubeChannel)

-- Drop the database if it already exists 
DROP DATABASE IF EXISTS DentalClinicDB;
-- Create the DB
CREATE DATABASE DentalClinicDB;
-- Use the DB, when creating tables we need to be working in the DB
USE DentalClinicDB;

-- Creating the tables

-- Table to store the data of the Specialist (as clinic, not profesional)
CREATE TABLE Specialist (
	-- Name of the attribute, data type (255 is a lot but just in case) and can't be NULL
	ClinicName varchar(255) NOT NULL,
	ClinicAddress varchar(255) NOT NULL,
	-- Need to Index this attribute. Sent an email asking about it.
    INDEX (ClinicAddress),
	-- This one can be NULL, and is an Integer data type
	ClinicTelfNo int NULL,
	-- Set primary key with literal constraint as it is a composite key
		-- There could be two different clinics with the same name 
	CONSTRAINT PK_Specialist PRIMARY KEY (ClinicName, ClinicAddress)
);

-- Table to store the different treatments and their price
CREATE TABLE Treatment (
	-- Treatment name as primary key 
	TreatmentName varchar(255) NOT NULL PRIMARY KEY,
	-- Not NULL: External Treatment is price 0, as it is 0 for out clinic
		-- Could be NULL as it is not known, but because we don't care, I think would be a misuse of the construct
	-- Decimal 6,2:
		-- Two digits after the decimal point, as it is a price
		-- 6 digits in total, 4+decimal. Assume we don't have treatment more expensive than 9,999.99
	TreatmentPrice DECIMAL(6,2) NOT NULL
);

-- Table to resolve the Many-to-Many relationship between Specialist and Treatment 
CREATE TABLE Specialization (
	TreatmentName varchar(255) NOT NULL,
	ClinicName varchar(255) NOT NULL,
	ClinicAddress varchar(255) NOT NULL,
	-- Primary key as the primary keys of the another tables
	CONSTRAINT PK_Specialization PRIMARY KEY (TreatmentName, ClinicName, ClinicAddress),
	-- Set the foreign keys to link with the another tables
	-- Set the attribute as FK, which table and attribute from the table references
    FOREIGN KEY (TreatmentName) REFERENCES Treatment (TreatmentName),
    FOREIGN KEY (ClinicName) REFERENCES Specialist (ClinicName),
    FOREIGN KEY (ClinicAddress) REFERENCES Specialist (ClinicAddress)
);

-- Table to store clients
CREATE TABLE Client (
	-- Auto Increment will set the attribute to the next No automatically (Leave NULL in INSERT)
	-- Primary key, as we cn have same clients with the rest of the attributes the same
	ClientNo int AUTO_INCREMENT NOT NULL PRIMARY KEY,
	FirstName varchar(255) NOT NULL,
	LastName varchar(255) NOT NULL,
	-- Date data type: e.g. '2020-01-01'
	DateOfBirth date NOT NULL,
	ClientAddress varchar(255) NOT NULL,
	-- If it has a debt or owes too much, set this to TRUE (View and Trigger)
	Defaulter boolean NOT NULL DEFAULT FALSE
);

-- Separete table as is a multivalued attribute
CREATE TABLE TelfNo (
	ClientNo int NOT NULL,
	TelfNo int NOT NULL,
	CONSTRAINT PK_TelfNo PRIMARY KEY (ClientNo, TelfNo),
    FOREIGN KEY (ClientNo) REFERENCES Client (ClientNo)
);

-- Table to store the appontments
CREATE TABLE Appointment (
	-- Similar to ClientNo
		-- PK could be AppDate+AppHour, but we will use NULLs in AppHour for another thing
	AppointmentNo int AUTO_INCREMENT NOT NULL PRIMARY KEY,
	AppDate date NOT NULL,
	-- Can be NULL if it's an external treatment, saved on appoitments for the history of the client
	-- Also, if it's a late cancelation, to have a record for the bill and to demonstrate it
	AppHour time NULL,
	-- If needs to be remainded of the appointment (Check if it has been remainded for next week's clients)
	Remainded boolean NOT NULL DEFAULT FALSE,
	-- If the client cancels in the last 24 hours, sep to TRUE and AppHour to NULL (Trigger)
	LateCancelation boolean NOT NULL DEFAULT FALSE,
	-- Link to the client
	ClientNo int NOT NULL,
	-- FK to link
    FOREIGN KEY (ClientNo) REFERENCES Client (ClientNo),
	-- To not have to appointments same day/hour
	-- MySQL treats NULLs as different values, so we can have multiple same AppDate with NULL AppHour (External specialist, LateCancelation)
	CONSTRAINT U_Appointment UNIQUE (AppDate, AppHour)	
);

-- Table to store the medical information of the appointment (For the record and for future appointments)
	-- Medical history of the patient
	-- To check by the doctor Next Week Treatments and prepare herself for what it comes
CREATE TABLE AppointmentDetails (
	-- Treatment done
	TreatmentName varchar(255) NOT NULL,
	-- Link to When has been done or when it is
	AppointmentNo int NOT NULL,
	-- Explanation of the work done. Can be NULL as it will be for future appointments 
	TreatmentDetails varchar(65535) NULL,
	-- For the receptionist, to see the instructions of the doctor about future appointments needed (view)
	FollowUp varchar(255) NULL,
	-- There can be more than one treatment per appointment, but not the same treatment twice
    CONSTRAINT PK_AppointmentDetails PRIMARY KEY (TreatmentName, AppointmentNo),
	-- Link to other tables
    FOREIGN KEY (TreatmentName) REFERENCES Treatment (TreatmentName),
    FOREIGN KEY (AppointmentNo) REFERENCES Appointment (AppointmentNo)
);

-- Bill of the appoitment
	-- There can be No Bill for follow ups, for example
		-- Or big Treatments that need multiple sessions, 1 Bill per treatment, not per session of it
		-- E.g. Denture - 500€ 1 Bill, following sessions for it "Follow up" with cost 0€
-- It's a 1-1 relationship, following GeeksForGeeks we could merge Bill+Appointment in one table, but doesn't feel right
	-- May be a problem as Normalization Requirements (They are all functionally dependant on Appointment), but it just doesn't feel right
		-- In the Module's notes I wrote it's optional to merge them...
		-- If we need a reason, let's say it's for readibility...
CREATE TABLE Bill (
	BillNo int AUTO_INCREMENT NOT NULL PRIMARY KEY,
	-- If not date inserted, take the current date
	BillDate date NOT NULL DEFAULT CURDATE(),
	Total DECIMAL(6,2) NOT NULL,
	-- If the Bill is gonna be paid in one go or many spaced over the time
	PaymentPlan int NOT NULL DEFAULT 1,
	AppointmentNo int NOT NULL,
	-- Maximun Payment plan: 6 different payments
    CONSTRAINT TypeOfPaymentPlan CHECK (PaymentPlan BETWEEN 1 AND 6),
    FOREIGN KEY (AppointmentNo) REFERENCES Appointment (AppointmentNo)
);

-- One Bill can have one or more Instalments.
	-- Idk if the term is correct so, is the bill splitted. One bill can be splitted up to 6 instalments (Payment Plan)
		-- Sum of instalments is the total of the bill
CREATE TABLE Instalment (
	InstalmentNo int AUTO_INCREMENT NOT NULL PRIMARY KEY,
	-- One bill can have multiple instalments, each of those in different Date (what would be the point if not)
	InstDate date NOT NULL,
	Total DECIMAL(6,2) NOT NULL,
	-- If it has been sent to the client to pay or still has to be sended
	InstSent BOOLEAN DEFAULT FALSE,
	-- Bill to which it belongs
	BillNo int NOT NULL,
    FOREIGN KEY (BillNo) REFERENCES Bill (BillNo)
);

-- Table to store payments made by the clients
CREATE TABLE Payment (
	PaymentNo int AUTO_INCREMENT NOT NULL PRIMARY KEY,
	-- Must be equal to one instalment not paid for the client, or Error (Trigger)
	Total DECIMAL(6,2) NOT NULL,
	PayDate date NOT NULL,
	-- Cash, Credit card...
	PaymentMethod varchar(255) NOT NULL,
	-- Who pays
	ClientNo int NOT NULL,
	-- What pays
	InstalmentNo int NULL DEFAULT NULL,
    FOREIGN KEY (ClientNo) REFERENCES Client (ClientNo),
    FOREIGN KEY (InstalmentNo) REFERENCES Instalment (InstalmentNo),
	-- Total must be positive (maybe error)
	CONSTRAINT validPayment CHECK (Total > 0)
);


