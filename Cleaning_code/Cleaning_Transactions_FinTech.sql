-- checking Transaction_ID column

SELECT * FROM Transactions_Fintech
WHERE Transaction_ID IS NULL OR Transaction_ID = '' OR Transaction_ID NOT LIKE 'TR_______';

WITH DuplicateCheck AS (
    SELECT Transaction_ID,
           ROW_NUMBER() OVER (PARTITION BY Transaction_ID ORDER BY Transaction_ID) as row_number
    FROM Transactions_Fintech
)
SELECT * FROM DuplicateCheck 
WHERE row_number > 1;

-- checking Booking_ID column

SELECT * FROM Transactions_Fintech
WHERE Booking_ID IS NULL OR Booking_ID = '' OR Booking_ID NOT LIKE 'BK______';

-- checking Payment_Method

SELECT DISTINCT Payment_Method FROM Transactions_Fintech;

-- checking Country

SELECT DISTINCT Country FROM Transactions_Fintech;

-- checking Status

SELECT DISTINCT Status FROM Transactions_Fintech;

-- checking IP_Address

SELECT * FROM Transactions_Fintech
WHERE IP_Address IS NULL OR IP_Address = '' OR IP_Address LIKE '%,%';

-- most importantly, checking if Transactions_Fintech.Booking_ID = Bookings_Clean.Booking_ID

SELECT COUNT(*)
FROM Transactions_Fintech
WHERE Booking_ID NOT IN (SELECT Booking_ID FROM Bookings_Clean);