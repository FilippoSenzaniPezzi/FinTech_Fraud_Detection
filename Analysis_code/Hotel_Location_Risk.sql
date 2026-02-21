SELECT 
    Municipality,
    Hotel_Type,
    COUNT(CASE WHEN Transaction_Status = 'Success' THEN 1 END) AS Total_Bookings_Success,
    SUM(CASE WHEN Transaction_Status = 'Success' THEN Expected_Revenue ELSE 0 END) AS Revenue_Confirmed,
    COUNT(CASE WHEN Transaction_Status = 'Failed' THEN 1 END) AS Total_Bookings_Failed,
    SUM(CASE WHEN Transaction_Status = 'Failed' THEN Expected_Revenue ELSE 0 END) AS Revenue_Lost,
    COUNT(CASE WHEN Transaction_Status = 'Chargeback' THEN 1 END) AS Total_Bookings_Chargeback,
    SUM(CASE WHEN Transaction_Status = 'Chargeback' THEN Expected_Revenue ELSE 0 END) AS Revenue_At_Risk,
    ROUND(
        SUM(CASE WHEN Transaction_Status IN ('Failed', 'Chargeback') THEN Expected_Revenue ELSE 0 END) * 100.0 / 
        NULLIF(SUM(Expected_Revenue), 0), 2
    ) AS Risk_Rate_Percentage
FROM View_Analytics_Final
GROUP BY Municipality, Hotel_Type
ORDER BY Risk_Rate_Percentage DESC;