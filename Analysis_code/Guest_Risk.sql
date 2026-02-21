SELECT 
	Customer_Name,
	Country,
	Booking_Date,
	Nights,
	Expected_Revenue,
	Payment_Method,
	IP_Address
FROM View_Analytics_Final
WHERE Municipality = 'San Candido' AND Transaction_Status = 'Chargeback'
ORDER BY Expected_Revenue DESC;

-- Focusing on IP addresses:

WITH Blacklisted_IPs AS (
    SELECT DISTINCT IP_Address
    FROM View_Analytics_Final
    WHERE Municipality = 'San Candido' AND Transaction_Status = 'Chargeback'
)
SELECT 
    V.IP_Address,
    V.Customer_Name,
    V.Municipality,
    V.Booking_Date,
    V.Expected_Revenue,
    V.Transaction_Status
FROM View_Analytics_Final V
JOIN Blacklisted_IPs B ON V.IP_Address = B.IP_Address
ORDER BY V.IP_Address, V.Booking_Date;