SELECT 
    Transaction_Status,
    COUNT(*) AS Total_Bookings,
    ROUND(AVG(Expected_Revenue), 1) AS AOV,
    ROUND(SUM(Expected_Revenue), 1) AS Total_Expected_Revenue
FROM View_Analytics_Final
GROUP BY Transaction_Status;	