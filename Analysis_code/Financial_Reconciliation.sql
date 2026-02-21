-- Comparing the total revenue obtained from the view with the one resulting from Bookings_Clean:

WITH View_Revenue_Totals AS (
  SELECT
    ROUND(
      SUM(CASE WHEN Transaction_Status = 'Success' THEN Expected_Revenue ELSE 0 END)
    + SUM(CASE WHEN Transaction_Status = 'Failed' THEN Expected_Revenue ELSE 0 END)
    + SUM(CASE WHEN Transaction_Status = 'Chargeback' THEN Expected_Revenue ELSE 0 END)
    + SUM(CASE WHEN Transaction_Status IS NULL THEN Expected_Revenue ELSE 0 END)
    , 2) AS View_Revenue_Total
  FROM View_Analytics_Final
),
Bookings_Clean_Totals AS (
  SELECT
    ROUND(SUM(Total_Amount), 2) AS Bookings_Clean_Total
  FROM Bookings_Clean
)

SELECT
  (SELECT View_Revenue_Total FROM View_Revenue_Totals)  AS View_Revenue_Totals,
  (SELECT Bookings_Clean_Total FROM Bookings_Clean_Totals) AS Bookings_Clean_Totals;