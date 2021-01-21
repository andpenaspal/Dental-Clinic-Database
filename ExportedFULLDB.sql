-- phpMyAdmin SQL Dump
-- version 5.0.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 22, 2020 at 05:34 PM
-- Server version: 10.4.11-MariaDB
-- PHP Version: 7.4.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `dentalclinicdb`
--

-- --------------------------------------------------------

--
-- Table structure for table `appointment`
--

CREATE TABLE `appointment` (
  `AppointmentNo` int(11) NOT NULL,
  `AppDate` date NOT NULL,
  `AppHour` time DEFAULT NULL,
  `Remainded` tinyint(1) NOT NULL DEFAULT 0,
  `LateCancelation` tinyint(1) NOT NULL DEFAULT 0,
  `ClientNo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `appointment`
--

INSERT INTO `appointment` (`AppointmentNo`, `AppDate`, `AppHour`, `Remainded`, `LateCancelation`, `ClientNo`) VALUES
(1, '2020-03-14', '10:00:00', 1, 0, 1),
(2, '2020-03-14', '10:30:00', 1, 0, 2),
(3, '2020-03-14', '11:00:00', 1, 0, 3),
(4, '2020-03-14', '12:00:00', 1, 0, 4),
(5, '2020-03-20', '10:00:00', 1, 0, 5),
(6, '2020-03-20', '11:00:00', 1, 0, 6),
(7, '2020-03-20', '11:30:00', 1, 0, 7),
(8, '2020-03-20', '10:30:00', 1, 0, 8),
(9, '2020-03-20', '16:00:00', 1, 0, 9),
(10, '2020-03-25', '10:00:00', 1, 0, 10),
(11, '2020-03-25', '10:30:00', 1, 0, 11),
(12, '2020-03-25', '11:00:00', 1, 0, 12),
(13, '2020-03-31', NULL, 1, 0, 1),
(14, '2020-03-28', '10:00:00', 1, 0, 3),
(15, '2020-03-27', NULL, 1, 0, 12),
(16, '2020-04-15', '10:00:00', 1, 0, 1),
(17, '2020-03-21', '16:30:00', 1, 0, 13),
(18, '2020-04-19', '10:00:00', 1, 0, 5),
(19, '2020-04-19', '10:30:00', 1, 0, 7),
(20, '2020-04-19', '11:30:00', 1, 0, 10),
(21, '2020-04-22', '10:00:00', 1, 0, 1),
(22, '2020-04-22', '10:30:00', 1, 0, 2),
(23, '2020-04-22', '11:00:00', 1, 0, 3),
(24, '2020-04-22', NULL, 1, 1, 4),
(25, '2020-06-14', '10:00:00', 0, 0, 2),
(26, '2020-06-12', '10:00:00', 0, 0, 3),
(27, '2020-06-14', '11:00:00', 0, 0, 4),
(28, '2020-06-12', '11:00:00', 0, 0, 8),
(29, '2020-06-14', '12:00:00', 0, 0, 11);

--
-- Triggers `appointment`
--
DELIMITER $$
CREATE TRIGGER `Bill_Late_Cancelation` AFTER UPDATE ON `appointment` FOR EACH ROW BEGIN
	IF NEW.LateCancelation = TRUE THEN
		-- Create Bill
		INSERT INTO Bill VALUES (NULL, OLD.AppDate, 20, 1, OLD.AppointmentNo);
		-- Delete entry from AppointmentDetails (To not show it in Next Week appointments)
		DELETE FROM appointmentdetails WHERE AppointmentNo=OLD.appointmentNO;
	END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Catch_Defaulters` BEFORE INSERT ON `appointment` FOR EACH ROW BEGIN
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
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `appointmentdetails`
--

CREATE TABLE `appointmentdetails` (
  `TreatmentName` varchar(255) NOT NULL,
  `AppointmentNo` int(11) NOT NULL,
  `TreatmentDetails` mediumtext DEFAULT NULL,
  `FollowUp` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `appointmentdetails`
--

INSERT INTO `appointmentdetails` (`TreatmentName`, `AppointmentNo`, `TreatmentDetails`, `FollowUp`) VALUES
('Bridge', 12, 'All fine', 'Refer for whitening'),
('Cleaning', 7, 'All fine', 'Not needed'),
('Crown', 2, 'All fine', 'Not needed'),
('Crown', 6, 'All fine', 'Not needed'),
('Denture', 9, 'All fine', 'Few weeks Follow up'),
('Denture', 11, 'All fine', 'Few weeks followUp'),
('Denture', 15, 'All fine', 'Few Weeks'),
('Denture FollowUp', 29, NULL, NULL),
('Examination', 1, 'Problems, sent for Veneers', 'Refer for Veneers'),
('Examination', 3, 'Discused Denture Options. Will think about it', 'Not needed'),
('Examination', 5, 'All fine', 'Not needed'),
('Examination', 10, 'All fine', 'Not needed'),
('Examination', 17, 'Allfine', 'Not needed'),
('Examination', 19, 'Allfine', 'Not needed'),
('Examination', 20, 'Allfine', 'Not needed'),
('Examination', 22, NULL, NULL),
('Examination', 23, NULL, NULL),
('Examination', 27, NULL, NULL),
('Filling', 8, 'All fine', 'Few weeks'),
('FollowUp', 16, 'All fine', 'Not needed'),
('FollowUp', 18, 'Allfine', 'Not needed'),
('FollowUp', 21, NULL, NULL),
('FollowUp', 25, NULL, NULL),
('FollowUp', 26, NULL, NULL),
('FollowUp', 28, NULL, NULL),
('Veneers', 13, 'Veneers done. Documents received', 'Not needed'),
('Whitening', 14, 'All fine', 'Not needed'),
('X-ray', 4, 'All fine, will see in few weeks how it is', 'Few weeks Examination');

-- --------------------------------------------------------

--
-- Table structure for table `bill`
--

CREATE TABLE `bill` (
  `BillNo` int(11) NOT NULL,
  `BillDate` date NOT NULL DEFAULT curdate(),
  `Total` decimal(6,2) NOT NULL,
  `PaymentPlan` int(11) NOT NULL DEFAULT 1,
  `AppointmentNo` int(11) NOT NULL
) ;

--
-- Dumping data for table `bill`
--

INSERT INTO `bill` (`BillNo`, `BillDate`, `Total`, `PaymentPlan`, `AppointmentNo`) VALUES
(1, '2020-03-14', '50.00', 1, 1),
(2, '2020-03-14', '50.00', 1, 2),
(3, '2020-03-14', '50.00', 1, 3),
(4, '2020-03-14', '150.00', 2, 4),
(5, '2020-03-20', '50.00', 1, 5),
(6, '2020-03-20', '50.00', 1, 6),
(7, '2020-03-20', '100.00', 1, 7),
(8, '2020-03-20', '70.00', 1, 8),
(9, '2020-03-20', '500.00', 6, 9),
(10, '2020-03-25', '50.00', 1, 10),
(11, '2020-03-25', '500.00', 6, 11),
(12, '2020-03-25', '250.00', 3, 12),
(13, '2020-03-28', '500.00', 6, 14),
(14, '2020-03-21', '50.00', 1, 17),
(15, '2020-04-19', '50.00', 1, 19),
(16, '2020-04-19', '50.00', 1, 20),
(17, '2020-04-22', '20.00', 1, 24);

--
-- Triggers `bill`
--
DELIMITER $$
CREATE TRIGGER `Set_Instalments` AFTER INSERT ON `bill` FOR EACH ROW BEGIN
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
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `check_defaulters`
-- (See below for the actual view)
--
CREATE TABLE `check_defaulters` (
`instalmentDate` date
,`clientNo` int(11)
,`instalmentNO` int(11)
,`total` decimal(6,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `client`
--

CREATE TABLE `client` (
  `ClientNo` int(11) NOT NULL,
  `FirstName` varchar(255) NOT NULL,
  `LastName` varchar(255) NOT NULL,
  `DateOfBirth` date NOT NULL,
  `ClientAddress` varchar(255) NOT NULL,
  `Defaulter` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `client`
--

INSERT INTO `client` (`ClientNo`, `FirstName`, `LastName`, `DateOfBirth`, `ClientAddress`, `Defaulter`) VALUES
(1, 'Andres', 'Penas', '1991-03-17', '123 Fake Street, Galway, Ireland', 0),
(2, 'Patrick', 'Smith', '1995-03-17', '123 Fake Street, Galway, Ireland', 0),
(3, 'John', 'Carter', '1981-03-21', '123 Fake Street, Cork, Ireland', 0),
(4, 'Robert', 'Smith', '1971-02-14', '123 Fake Street, Dublin, Ireland', 0),
(5, 'Eoin', 'Jordan', '1984-03-25', '123 Fake Street, Galway, Ireland', 0),
(6, 'Emma', 'Smith', '1990-05-28', '123 Fake Street, Galway, Ireland', 1),
(7, 'Cora', 'Gasol', '1977-03-28', '123 Fake Street, Galway, Ireland', 1),
(8, 'Melissa', 'Smith', '1969-08-22', '123 Fake Street, Galway, Ireland', 0),
(9, 'Peter', 'Garnet', '1992-04-04', '123 Fake Street, Galway, Ireland', 1),
(10, 'Lisa', 'Smith', '1981-11-01', '123 Fake Street, Galway, Ireland', 0),
(11, 'Laura', 'James', '1987-12-07', '123 Fake Street, Galway, Ireland', 0),
(12, 'Sean', 'Smith', '1991-04-17', '123 Fake Street, Galway, Ireland', 0),
(13, 'Jack', 'Sparrow', '1990-06-01', '123 Fake Street, Galway, Ireland', 0);

-- --------------------------------------------------------

--
-- Stand-in structure for view `followup`
-- (See below for the actual view)
--
CREATE TABLE `followup` (
`ClientNo` int(11)
,`appDate` date
,`appHour` time
,`treatmentname` varchar(255)
,`treatmentprice` decimal(6,2)
,`followup` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `instalment`
--

CREATE TABLE `instalment` (
  `InstalmentNo` int(11) NOT NULL,
  `InstDate` date NOT NULL,
  `Total` decimal(6,2) NOT NULL,
  `InstSent` tinyint(1) DEFAULT 0,
  `BillNo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `instalment`
--

INSERT INTO `instalment` (`InstalmentNo`, `InstDate`, `Total`, `InstSent`, `BillNo`) VALUES
(1, '2020-03-14', '50.00', 0, 1),
(2, '2020-03-14', '50.00', 0, 2),
(3, '2020-03-14', '50.00', 0, 3),
(4, '2020-03-14', '75.00', 0, 4),
(5, '2020-04-14', '75.00', 0, 4),
(6, '2020-03-20', '50.00', 0, 5),
(7, '2020-03-20', '50.00', 0, 6),
(8, '2020-03-20', '100.00', 0, 7),
(9, '2020-03-20', '70.00', 0, 8),
(10, '2020-03-20', '83.33', 0, 9),
(11, '2020-04-20', '83.33', 0, 9),
(12, '2020-05-20', '83.33', 0, 9),
(13, '2020-06-20', '83.33', 0, 9),
(14, '2020-07-20', '83.33', 0, 9),
(15, '2020-08-20', '83.33', 0, 9),
(16, '2020-03-25', '50.00', 0, 10),
(17, '2020-03-25', '83.33', 0, 11),
(18, '2020-04-25', '83.33', 0, 11),
(19, '2020-05-25', '83.33', 0, 11),
(20, '2020-06-25', '83.33', 0, 11),
(21, '2020-07-25', '83.33', 0, 11),
(22, '2020-08-25', '83.33', 0, 11),
(23, '2020-03-25', '83.33', 0, 12),
(24, '2020-04-25', '83.33', 0, 12),
(25, '2020-05-25', '83.33', 0, 12),
(26, '2020-03-28', '83.33', 0, 13),
(27, '2020-04-28', '83.33', 0, 13),
(28, '2020-05-28', '83.33', 0, 13),
(29, '2020-06-28', '83.33', 0, 13),
(30, '2020-07-28', '83.33', 0, 13),
(31, '2020-08-28', '83.33', 0, 13),
(32, '2020-03-21', '50.00', 0, 14),
(33, '2020-04-19', '50.00', 0, 15),
(34, '2020-04-19', '50.00', 0, 16),
(35, '2020-04-22', '20.00', 0, 17);

-- --------------------------------------------------------

--
-- Stand-in structure for view `latecancelations`
-- (See below for the actual view)
--
CREATE TABLE `latecancelations` (
`clientNo` int(11)
,`AppDate` date
,`LateCancelation` tinyint(1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `medicalhistory`
-- (See below for the actual view)
--
CREATE TABLE `medicalhistory` (
`ClientNo` int(11)
,`appDate` date
,`treatmentname` varchar(255)
,`treatmentdetails` mediumtext
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `nextweek_appoitments`
-- (See below for the actual view)
--
CREATE TABLE `nextweek_appoitments` (
`clientNo` int(11)
,`AppDate` date
,`AppHour` time
,`remainded` tinyint(1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `nextweek_treatmens`
-- (See below for the actual view)
--
CREATE TABLE `nextweek_treatmens` (
`ClientNo` int(11)
,`AppDate` date
,`AppHour` time
,`TreatmentName` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

CREATE TABLE `payment` (
  `PaymentNo` int(11) NOT NULL,
  `Total` decimal(6,2) NOT NULL,
  `PayDate` date NOT NULL,
  `PaymentMethod` varchar(255) NOT NULL,
  `ClientNo` int(11) NOT NULL,
  `InstalmentNo` int(11) DEFAULT NULL
) ;

--
-- Dumping data for table `payment`
--

INSERT INTO `payment` (`PaymentNo`, `Total`, `PayDate`, `PaymentMethod`, `ClientNo`, `InstalmentNo`) VALUES
(1, '50.00', '2020-03-18', 'Cash', 1, 1),
(2, '50.00', '2020-03-19', 'Cash', 2, 2),
(3, '50.00', '2020-03-20', 'Credit Card', 3, 3),
(4, '75.00', '2020-03-19', 'Cash', 4, 4),
(5, '50.00', '2020-03-21', 'Credit Card', 5, 6),
(6, '100.00', '2020-03-23', 'Cash', 7, 8),
(7, '70.00', '2020-03-25', 'Cash', 8, 9),
(8, '83.33', '2020-03-24', 'Credit Card', 9, 10),
(9, '50.00', '2020-03-26', 'Cash', 10, 16),
(10, '83.33', '2020-03-29', 'Cash', 11, 17),
(11, '83.33', '2020-03-30', 'Cash', 12, 23),
(12, '75.00', '2020-04-16', 'Credit Card', 4, 5),
(13, '83.33', '2020-04-25', 'Credit Card', 11, 18),
(14, '83.33', '2020-04-30', 'Cash', 12, 24),
(15, '83.33', '2020-04-05', 'Credit Card', 3, 26);

--
-- Triggers `payment`
--
DELIMITER $$
CREATE TRIGGER `look_For_Instalment` BEFORE INSERT ON `payment` FOR EACH ROW BEGIN
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
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `send_instalments`
-- (See below for the actual view)
--
CREATE TABLE `send_instalments` (
`ClientNo` int(11)
,`instalmentNO` int(11)
,`instsent` tinyint(1)
);

-- --------------------------------------------------------

--
-- Table structure for table `specialist`
--

CREATE TABLE `specialist` (
  `ClinicName` varchar(255) NOT NULL,
  `ClinicAddress` varchar(255) NOT NULL,
  `ClinicTelfNo` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `specialist`
--

INSERT INTO `specialist` (`ClinicName`, `ClinicAddress`, `ClinicTelfNo`) VALUES
('Casserly\'s Dental Clinic', '789 Fake Street, Cork City, Cork, Ireland', 85876543),
('McCarthy\'s Dental Clinic', '456 Fake Street, Cork City, Cork, Ireland', 85456789),
('Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland', 85123456);

-- --------------------------------------------------------

--
-- Table structure for table `specialization`
--

CREATE TABLE `specialization` (
  `TreatmentName` varchar(255) NOT NULL,
  `ClinicName` varchar(255) NOT NULL,
  `ClinicAddress` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `specialization`
--

INSERT INTO `specialization` (`TreatmentName`, `ClinicName`, `ClinicAddress`) VALUES
('Bridge', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
('Cleaning', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
('Crown', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
('Denture', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
('Denture FollowUp', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
('Examination', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
('Filling', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
('FollowUp', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland'),
('Veneers', 'McCarthy\'s Dental Clinic', '456 Fake Street, Cork City, Cork, Ireland'),
('Whitening', 'Casserly\'s Dental Clinic', '789 Fake Street, Cork City, Cork, Ireland'),
('X-ray', 'Mulcahy\'s Dental Clinic', '123 Fake Street, Cork City, Cork, Ireland');

-- --------------------------------------------------------

--
-- Table structure for table `telfno`
--

CREATE TABLE `telfno` (
  `ClientNo` int(11) NOT NULL,
  `TelfNo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `telfno`
--

INSERT INTO `telfno` (`ClientNo`, `TelfNo`) VALUES
(1, 891230000),
(1, 891234567),
(2, 891234567),
(3, 891234567),
(4, 891234567);

-- --------------------------------------------------------

--
-- Table structure for table `treatment`
--

CREATE TABLE `treatment` (
  `TreatmentName` varchar(255) NOT NULL,
  `TreatmentPrice` decimal(6,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `treatment`
--

INSERT INTO `treatment` (`TreatmentName`, `TreatmentPrice`) VALUES
('Bridge', '250.00'),
('Cleaning', '100.00'),
('Crown', '50.00'),
('Denture', '500.00'),
('Denture FollowUp', '0.00'),
('Examination', '50.00'),
('Filling', '70.00'),
('FollowUp', '0.00'),
('Veneers', '0.00'),
('Whitening', '0.00'),
('X-Ray', '150.00');

-- --------------------------------------------------------

--
-- Structure for view `check_defaulters`
--
DROP TABLE IF EXISTS `check_defaulters`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `check_defaulters`  AS  select min(`instalment`.`InstDate`) AS `instalmentDate`,`appointment`.`ClientNo` AS `clientNo`,`instalment`.`InstalmentNo` AS `instalmentNO`,`instalment`.`Total` AS `total` from (((`client` join `instalment`) join `appointment`) join `bill`) where (curdate() > (select min(`instalment`.`InstDate`) + interval 1 month) or curdate() > (select min(`instalment`.`InstDate`) + interval 10 day) and `instalment`.`Total` > 99.99) and `appointment`.`ClientNo` = `client`.`ClientNo` and `client`.`Defaulter` = 0 and `appointment`.`AppointmentNo` = `bill`.`AppointmentNo` and `bill`.`BillNo` = `instalment`.`BillNo` and !(`instalment`.`InstalmentNo` in (select `payment`.`InstalmentNo` from `payment`)) group by `appointment`.`ClientNo` ;

-- --------------------------------------------------------

--
-- Structure for view `followup`
--
DROP TABLE IF EXISTS `followup`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `followup`  AS  select `appointment`.`ClientNo` AS `ClientNo`,`appointment`.`AppDate` AS `appDate`,`appointment`.`AppHour` AS `appHour`,`appointmentdetails`.`TreatmentName` AS `treatmentname`,`treatment`.`TreatmentPrice` AS `treatmentprice`,`appointmentdetails`.`FollowUp` AS `followup` from ((`appointment` join `appointmentdetails`) join `treatment`) where `appointment`.`AppointmentNo` = `appointmentdetails`.`AppointmentNo` and `treatment`.`TreatmentName` = `appointmentdetails`.`TreatmentName` and `appointment`.`AppDate` = curdate() ;

-- --------------------------------------------------------

--
-- Structure for view `latecancelations`
--
DROP TABLE IF EXISTS `latecancelations`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `latecancelations`  AS  select `appointment`.`ClientNo` AS `clientNo`,`appointment`.`AppDate` AS `AppDate`,`appointment`.`LateCancelation` AS `LateCancelation` from `appointment` where `appointment`.`LateCancelation` = 1 ;

-- --------------------------------------------------------

--
-- Structure for view `medicalhistory`
--
DROP TABLE IF EXISTS `medicalhistory`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `medicalhistory`  AS  select `appointment`.`ClientNo` AS `ClientNo`,`appointment`.`AppDate` AS `appDate`,`appointmentdetails`.`TreatmentName` AS `treatmentname`,`appointmentdetails`.`TreatmentDetails` AS `treatmentdetails` from (`appointment` join `appointmentdetails`) where `appointment`.`LateCancelation` = 0 and `appointment`.`AppDate` <= curdate() and `appointment`.`AppointmentNo` = `appointmentdetails`.`AppointmentNo` and `appointment`.`AppDate` <= curdate() ;

-- --------------------------------------------------------

--
-- Structure for view `nextweek_appoitments`
--
DROP TABLE IF EXISTS `nextweek_appoitments`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `nextweek_appoitments`  AS  select `appointment`.`ClientNo` AS `clientNo`,`appointment`.`AppDate` AS `AppDate`,`appointment`.`AppHour` AS `AppHour`,`appointment`.`Remainded` AS `remainded` from `appointment` where `appointment`.`AppHour` is not null and `appointment`.`AppDate` between curdate() and curdate() + interval 10 day ;

-- --------------------------------------------------------

--
-- Structure for view `nextweek_treatmens`
--
DROP TABLE IF EXISTS `nextweek_treatmens`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `nextweek_treatmens`  AS  select `appointment`.`ClientNo` AS `ClientNo`,`appointment`.`AppDate` AS `AppDate`,`appointment`.`AppHour` AS `AppHour`,`appointmentdetails`.`TreatmentName` AS `TreatmentName` from (`appointment` join `appointmentdetails`) where `appointment`.`AppointmentNo` = `appointmentdetails`.`AppointmentNo` and `appointment`.`AppDate` between curdate() and curdate() + interval 10 day ;

-- --------------------------------------------------------

--
-- Structure for view `send_instalments`
--
DROP TABLE IF EXISTS `send_instalments`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `send_instalments`  AS  select `appointment`.`ClientNo` AS `ClientNo`,`instalment`.`InstalmentNo` AS `instalmentNO`,`instalment`.`InstSent` AS `instsent` from ((`appointment` join `instalment`) join `bill`) where `instalment`.`BillNo` = `bill`.`BillNo` and `bill`.`AppointmentNo` = `appointment`.`AppointmentNo` and `instalment`.`InstDate` between curdate() + interval -10 day and curdate() ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `appointment`
--
ALTER TABLE `appointment`
  ADD PRIMARY KEY (`AppointmentNo`),
  ADD UNIQUE KEY `U_Appointment` (`AppDate`,`AppHour`),
  ADD KEY `ClientNo` (`ClientNo`);

--
-- Indexes for table `appointmentdetails`
--
ALTER TABLE `appointmentdetails`
  ADD PRIMARY KEY (`TreatmentName`,`AppointmentNo`),
  ADD KEY `AppointmentNo` (`AppointmentNo`);

--
-- Indexes for table `bill`
--
ALTER TABLE `bill`
  ADD PRIMARY KEY (`BillNo`),
  ADD KEY `AppointmentNo` (`AppointmentNo`);

--
-- Indexes for table `client`
--
ALTER TABLE `client`
  ADD PRIMARY KEY (`ClientNo`);

--
-- Indexes for table `instalment`
--
ALTER TABLE `instalment`
  ADD PRIMARY KEY (`InstalmentNo`),
  ADD KEY `BillNo` (`BillNo`);

--
-- Indexes for table `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`PaymentNo`),
  ADD KEY `ClientNo` (`ClientNo`),
  ADD KEY `InstalmentNo` (`InstalmentNo`);

--
-- Indexes for table `specialist`
--
ALTER TABLE `specialist`
  ADD PRIMARY KEY (`ClinicName`,`ClinicAddress`),
  ADD KEY `ClinicAddress` (`ClinicAddress`);

--
-- Indexes for table `specialization`
--
ALTER TABLE `specialization`
  ADD PRIMARY KEY (`TreatmentName`,`ClinicName`,`ClinicAddress`),
  ADD KEY `ClinicName` (`ClinicName`),
  ADD KEY `ClinicAddress` (`ClinicAddress`);

--
-- Indexes for table `telfno`
--
ALTER TABLE `telfno`
  ADD PRIMARY KEY (`ClientNo`,`TelfNo`);

--
-- Indexes for table `treatment`
--
ALTER TABLE `treatment`
  ADD PRIMARY KEY (`TreatmentName`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointment`
--
ALTER TABLE `appointment`
  MODIFY `AppointmentNo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `bill`
--
ALTER TABLE `bill`
  MODIFY `BillNo` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `client`
--
ALTER TABLE `client`
  MODIFY `ClientNo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `instalment`
--
ALTER TABLE `instalment`
  MODIFY `InstalmentNo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `payment`
--
ALTER TABLE `payment`
  MODIFY `PaymentNo` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointment`
--
ALTER TABLE `appointment`
  ADD CONSTRAINT `appointment_ibfk_1` FOREIGN KEY (`ClientNo`) REFERENCES `client` (`ClientNo`);

--
-- Constraints for table `appointmentdetails`
--
ALTER TABLE `appointmentdetails`
  ADD CONSTRAINT `appointmentdetails_ibfk_1` FOREIGN KEY (`TreatmentName`) REFERENCES `treatment` (`TreatmentName`),
  ADD CONSTRAINT `appointmentdetails_ibfk_2` FOREIGN KEY (`AppointmentNo`) REFERENCES `appointment` (`AppointmentNo`);

--
-- Constraints for table `bill`
--
ALTER TABLE `bill`
  ADD CONSTRAINT `bill_ibfk_1` FOREIGN KEY (`AppointmentNo`) REFERENCES `appointment` (`AppointmentNo`);

--
-- Constraints for table `instalment`
--
ALTER TABLE `instalment`
  ADD CONSTRAINT `instalment_ibfk_1` FOREIGN KEY (`BillNo`) REFERENCES `bill` (`BillNo`);

--
-- Constraints for table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`ClientNo`) REFERENCES `client` (`ClientNo`),
  ADD CONSTRAINT `payment_ibfk_2` FOREIGN KEY (`InstalmentNo`) REFERENCES `instalment` (`InstalmentNo`);

--
-- Constraints for table `specialization`
--
ALTER TABLE `specialization`
  ADD CONSTRAINT `specialization_ibfk_1` FOREIGN KEY (`TreatmentName`) REFERENCES `treatment` (`TreatmentName`),
  ADD CONSTRAINT `specialization_ibfk_2` FOREIGN KEY (`ClinicName`) REFERENCES `specialist` (`ClinicName`),
  ADD CONSTRAINT `specialization_ibfk_3` FOREIGN KEY (`ClinicAddress`) REFERENCES `specialist` (`ClinicAddress`);

--
-- Constraints for table `telfno`
--
ALTER TABLE `telfno`
  ADD CONSTRAINT `telfno_ibfk_1` FOREIGN KEY (`ClientNo`) REFERENCES `client` (`ClientNo`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
