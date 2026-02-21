CREATE VIEW View_Analytics_Final AS
SELECT 
    B.Booking_ID,
    B.Customer_Name,
    T.Country,
    B.Booking_Date,
    B.Nights,
    H.Municipality,
    H.Type AS Hotel_Type,
    H.Price_Range,
    B.Total_Amount AS Expected_Revenue,
    T.Transaction_ID,
    T.Payment_Method,
    T.Status AS Transaction_Status,
    T.IP_Address
FROM Bookings_Clean B
LEFT JOIN Hotel_Master H ON B.Hotel_ID = H.Hotel_ID
LEFT JOIN Transactions_Fintech T ON B.Booking_ID = T.Booking_ID;