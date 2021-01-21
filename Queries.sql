USE DentalClinicDB;

-- Queries to try on the DB

-- SELECT
    -- Select treatments with a cost above 100€
    SELECT * FROM Treatment WHERE TreatmentPrice > 100;

-- INSERT
    -- Insert a new phone number
    INSERT INTO TelfNo VALUES (6, 0899877654);

-- UPDATE
    -- Update the phone number
    UPDATE TelfNo SET TelfNo = 0894573513 WHERE ClientNo=6;

-- DELETE
    -- Delete the phone number
    DELETE FROM TelfNo WHERE ClientNo=6;

-- CREATE
    -- Create a view with people born after 1990
    CREATE VIEW Young_People AS SELECT ClientNo, FirstName, LastName, DateOfBirth FROM Client WHERE DateOfBirth > '1990-01-01';