SELECT 
    '1. Gross Bookings' AS Step, -- temporary column harcoding
    COUNT(*) AS Total_Transactions,
    SUM(Expected_Revenue) AS Volume_EUR
FROM View_Analytics_Final

UNION ALL

SELECT 
    '2. Authorized Payments' AS Step, -- temporary column harcoding
    COUNT(*) AS Total_Transactions,
    ROUND(SUM(Expected_Revenue), 1) AS Volume_EUR
FROM View_Analytics_Final
WHERE Transaction_Status = 'Success'

UNION ALL

SELECT 
    '3. Net Revenue' AS Step, -- temporary column harcoding
	(SELECT COUNT(*) FROM View_Analytics_Final WHERE Transaction_Status = 'Success') - 
	(SELECT COUNT(*) FROM View_Analytics_Final WHERE Transaction_Status = 'Chargeback') AS Total_Transactions,
    (SELECT ROUND(SUM(Expected_Revenue), 1) FROM View_Analytics_Final WHERE Transaction_Status = 'Success') - 
	(SELECT ROUND(SUM(Expected_Revenue), 1) FROM View_Analytics_Final WHERE Transaction_Status = 'Chargeback') AS Volume_EUR;