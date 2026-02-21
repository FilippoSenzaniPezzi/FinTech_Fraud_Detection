-- checking Booking_ID column

SELECT * FROM Bookings_Raw
WHERE Booking_ID IS NULL OR Booking_ID = '' OR Booking_ID NOT LIKE 'BK______';

WITH DuplicateCheck AS (
    SELECT Booking_ID,
           ROW_NUMBER() OVER (PARTITION BY Booking_ID ORDER BY Booking_Date DESC) as row_number
    FROM Bookings_Raw -- in case of duplicates, order them from the most recent booking
)
SELECT * FROM DuplicateCheck 
WHERE row_number > 1;

-- checking and cleaning Hotel_ID column

SELECT DISTINCT Hotel_ID FROM Bookings_Raw;
SELECT COUNT(*) FROM Bookings_Raw
WHERE Hotel_ID = 'H_UNK';

-- classifying as "Unknown_Hotel" the 24 bookings with "H_UNK" as Hotel_ID

ALTER TABLE Bookings_Raw
ADD COLUMN Hotel_ID_Clean VARCHAR;

UPDATE Bookings_Raw
SET Hotel_ID_Clean = 
	CASE WHEN Hotel_ID = 'H_UNK' THEN 'Unknown Hotel'
	ELSE Hotel_ID
END;

-- checking and cleaning Customer_Name column

SELECT DISTINCT Customer_Name FROM Bookings_Raw;
SELECT COUNT(*) FROM Bookings_Raw
WHERE Customer_Name IS NULL OR Customer_Name = '';

-- deliting 'Mr.', 'Mrs.' and 'Dr.' from Customer_Name column

UPDATE Bookings_Raw 
SET Customer_Name = REPLACE(REPLACE(REPLACE(Customer_Name, 'Mr. ', ''), 'MR. ', ''), 'mr. ', '') 
WHERE Customer_Name LIKE 'Mr. %' 
	OR Customer_Name LIKE 'MR. %' 
	OR Customer_Name LIKE 'mr. %';

UPDATE Bookings_Raw 
SET Customer_Name = REPLACE(REPLACE(REPLACE(Customer_Name, 'Mrs. ', ''), 'MRS. ', ''), 'mrs. ', '') 
WHERE Customer_Name LIKE 'Mrs. %' 
	OR Customer_Name LIKE 'MRS. %' 
	OR Customer_Name LIKE 'mrs. %';

UPDATE Bookings_Raw
SET Customer_Name = REPLACE(REPLACE(REPLACE(Customer_Name, 'Dr. ', ''), 'DR. ', ''), 'dr. ', '') 
WHERE Customer_Name LIKE 'Dr. %' 
	OR Customer_Name LIKE 'DR. %' 
	OR Customer_Name LIKE 'dr. %';

-- creating the clean column with proper case name and surname

ALTER TABLE Bookings_Raw
ADD COLUMN Customer_Name_Clean VARCHAR;

UPDATE Bookings_Raw
SET Customer_Name_Clean =
    -- 1. Name: Capital letter + rest of the name in lowercase
    UPPER(SUBSTR(TRIM(Customer_Name), 1, 1)) || 
    LOWER(SUBSTR(TRIM(Customer_Name), 2, INSTR(TRIM(Customer_Name), ' ') - 2)) || 
    
    ' ' || -- Adding a space between name and surname
    
    -- 2. Surname: Capital letter + rest of the surname in lowercase
    UPPER(SUBSTR(TRIM(Customer_Name), INSTR(TRIM(Customer_Name), ' ') + 1, 1)) || 
    LOWER(SUBSTR(TRIM(Customer_Name), INSTR(TRIM(Customer_Name), ' ') + 2))
WHERE INSTR(TRIM(Customer_Name), ' ') > 0;

-- checking if all costumers have just name and surname

SELECT * FROM Bookings_Raw
WHERE Customer_Name_Clean LIKE '% % %';

/* 30 costumers' full names have more than just first and last name: some end with 'jr.', some with 'iii', and so on.
First, I set 'iii' and 'jr.' with capital letter, then I discard titles like 'phd':
*/

UPDATE Bookings_Raw
SET Customer_Name_Clean = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Customer_Name_Clean, ' iii', ' III'), ' jr.', ' Jr.'),
' phd', ''), ' dvm', ''), ' dds', ''), ' md', ''))
WHERE Customer_Name_Clean LIKE '%iii' 
	OR Customer_Name_Clean LIKE '%jr.' 
	OR Customer_Name_Clean LIKE '%md'
	OR Customer_Name_Clean LIKE '%dds' 
	OR Customer_Name_Clean LIKE '%dvm' 
	OR Customer_Name_Clean LIKE '%phd';

-- Fixing a couple of surnames: "Oconnor" to "O'Connor"

SELECT Customer_Name_Clean FROM Bookings_Raw
WHERE Customer_Name_Clean LIKE '% O%';

UPDATE Bookings_Raw
SET Customer_Name_Clean = REPLACE(Customer_Name_Clean, "Oconnor", "O'Connor")
WHERE Customer_Name_Clean LIKE '% O%';

-- checking and cleaning Booking_Date column

SELECT * FROM Bookings_Raw
WHERE Booking_Date IS NULL
	OR Booking_Date = ''
	OR LENGTH(Booking_Date) != 10 
    OR SUBSTR(Booking_Date, 5, 1) != '-' 
    OR SUBSTR(Booking_Date, 8, 1) != '-'
	OR Booking_Date > '2026-02-28';

SELECT 
    Booking_Date,
    STRFTIME('%Y', Booking_Date) AS Year,
    STRFTIME('%m', Booking_Date) AS Month,
    STRFTIME('%d', Booking_Date) AS Day
FROM Bookings_Raw
WHERE "Day"  IS NULL OR "Month" IS NULL OR "Year" IS NULL;

-- everything seems fine, so I create a new clean column where I make sure all these dates are set as DATE format

ALTER TABLE Bookings_Raw
ADD COLUMN Booking_Date_Clean DATE;

UPDATE Bookings_Raw
SET Booking_Date_Clean = DATE(TRIM(Booking_Date))
WHERE Booking_Date IS NOT NULL;

-- checking and cleaning Nights column

SELECT * FROM Bookings_Raw
WHERE Nights < 1 OR Nights IS NULL OR Nights = '';

/* 30 bookings have '-1' as number of nights, probably it's a bug in the booking system, where the check out date has been set
the day before the check in date. I replace them with NULL values, so that they won't affect the AVG in case I'll perform it,
for example, on the Tableau dashboard.
*/

ALTER TABLE Bookings_Raw
ADD COLUMN Nights_Clean INTEGER;

UPDATE Bookings_Raw
SET Nights_Clean = 
	CASE WHEN Nights < 1 THEN NULL
	ELSE Nights
END;

-- checking and cleaning Total_Amount column

SELECT * FROM Bookings_Raw
WHERE Total_Amount < 1 OR Total_Amount IS NULL OR Total_Amount = '' OR Total_Amount LIKE '%,%';

-- 83 bookings show either an empty or a negative Total_Amount. I treat them in the same way I've done with Nights column:

ALTER TABLE Bookings_Raw
ADD COLUMN Total_Amount_Clean DECIMAL(10,2);

UPDATE Bookings_Raw
SET Total_Amount_Clean = 
	CASE WHEN Total_Amount < 1 OR Total_Amount = '' THEN NULL
	ELSE Total_Amount
END;

/* Now that I cleaned all the columns, I'll display them onto a new Bookings_Clean table
 */

CREATE TABLE Bookings_Clean (
    Booking_ID VARCHAR,
    Hotel_ID VARCHAR,
    Customer_Name VARCHAR,
    Booking_Date DATE,
    Nights INTEGER,
    Total_Amount DECIMAL(10,2)
);

INSERT INTO Bookings_Clean
SELECT 
    Booking_ID,
    Hotel_ID_Clean,
    Customer_Name_Clean,
    Booking_Date_Clean,
    Nights_Clean,
    Total_Amount_Clean
FROM Bookings_Raw;