# End-to-End Hotel Transactions Analysis: Python Synthetic Generation & SQL Cleansing for Fraud Detection

## Executive Summary

Using Python and SQL, I created a fictitious database of hotel transactions, cleaned it, and analyzed possible fraud patterns. Since I don't have access to a real database, I created a synthetic one coding with Python. It means that I already know how many chargebacks and how many failed transactions there are, and in which hotel they are located. Therefore, the aim of this project is not to spot these insights, because they've already been synthetically generated; the goal is to show how, in a real world scenario, I would work to detect possible frauds and what would be my suggestions to prevent them.

## Business Problem

A hotel chain decided to expand its business following the recommendations gathered from [my previous work](https://github.com/FilippoSenzaniPezzi/Analysis_Tourism_Trends_Italy_2014-2024). Six months after the opening, their booking system showed several chargeback or failed transactions, spread among the 5 hotels they opened across Italy. What's the "weight" of chargebacks? Are they the main problem, or failed transactions have a higher impact on the business economy?

## Methodology

- Python to generate the synthetic database
- SQL to clean and analyse it

## Skills

- Python: Pandas, NumPy, Faker, logic-based data simulation, data dirtying techniques
- SQL: CTEs, window functions, joins, "case-when" conditional logic, aggregate functions, view creation

## The Database

Faker [Python](Fictitious_database/data_generator.ipynb) library allowed to generate a [fictitious database](Fictitious_database) made of three raw tables: "Bookings_Raw", "Hotel_Master" and "Transactions_Fintech". The first step has been to [clean up](Cleaning_code) these tables using SQL. Once ready, I joined the tables in a final [view](Cleaning_code/Creating_View.sql), which brought 2 main advantages compared to the creation of another real table:
1. If, in future, the three tables are updated, the view will automatically update; basically, the view doesn't save the data, but the code used to analyse those data, so that if the input data changes, the code is still the same and the result can be automatically updated.
2. Views are more efficient because they don't occupy further memory space.

## Data Analysis using SQL Queries

### Financial Reconciliation

Ideally, a column named "Total_Amount" should have been present in both "Bookings_Clean" and "Transactions_Fintech" tables, in order to see if all the bookings have been correctly paid for. In this case, "Transactions_Fintech" didn't show this kind of column, but it did display a transaction status. Thus, I calculated the total revenue for each status:
```sql
SELECT 
    SUM(CASE WHEN Transaction_Status = 'Success' THEN Expected_Revenue ELSE 0 END) AS "Revenue Confirmed",
    SUM(CASE WHEN Transaction_Status = 'Failed' THEN Expected_Revenue ELSE 0 END) AS "Revenue Lost",
    SUM(CASE WHEN Transaction_Status = 'Chargeback' THEN Expected_Revenue ELSE 0 END) AS "Revenue at Risk",
    SUM(CASE WHEN Transaction_Status IS NULL THEN Expected_Revenue ELSE 0 END) AS "Revenue Unpaid"
FROM View_Analytics_Final;
```
|Revenue Confirmed|Revenue Lost|Revenue at Risk|Revenue Unpaid|
|-----------------|------------|---------------|--------------|
|2386043.57€|41743.49€|16814.24€|0|

Adding up these three numbers, it returns a value 46.958,47€ lower than the total revenue [calculated](Analysis_code/Financial_Reconciliation.sql) using "Bookings_Clean", which should't be the case. So I counted the total number of rows, realising that the view contained 1476 rows, 24 less than "Bookings_Clean". The reason lay in how the view has been originally coded:
```sql
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
JOIN Hotel_Master H ON B.Hotel_ID = H.Hotel_ID
LEFT JOIN Transactions_Fintech T ON B.Booking_ID = T.Booking_ID;
```
Why, in the first place, did I use `JOIN` on "Hotel_ID" and `LEFT JOIN` on "Booking_ID"? The choice was made to preserve future data input: if a new booking is added without a "Hotel_ID", the use of `(INNER) JOIN` will filter out that row. At the same time, if 100 more transactions are added, out of which only 80 have been paid for, the use of `LEFT JOIN` allows to display all the 100 transactions, and not only the 80 paid for, that I would see if I use `INNER JOIN`.

As mentioned earlier, this choice in coding the view has actually arisen a problem, because that `INNER JOIN` used on "Hotel_ID" filtered out some bookings, the ones with unknown ID. In fact, running
```sql
SELECT COUNT(Hotel_ID) FROM Bookings_Clean
WHERE Hotel_ID = "Unknown Hotel";
```
returns exactly 24, the rows missing to reach 1500. Since these bookings with unknown hotel ID were costing almost 47000€, I decided not to ignore them anymore, changing the view `INNER JOIN` with a `LEFT JOIN`.

### Hotel Location Risk

Which locations are causing 41743.49€ of revenue lost and 16814.24€ of revenue at risk?
```sql
SELECT 
    Municipality,
    Hotel_Type,
    COUNT(CASE WHEN Transaction_Status = 'Success' THEN 1 END) AS "Total Bookings Success",
    SUM(CASE WHEN Transaction_Status = 'Success' THEN Expected_Revenue ELSE 0 END) AS "Revenue Confirmed",
    COUNT(CASE WHEN Transaction_Status = 'Failed' THEN 1 END) AS "Total_Bookings_Failed",
    SUM(CASE WHEN Transaction_Status = 'Failed' THEN Expected_Revenue ELSE 0 END) AS "Revenue Lost",
    COUNT(CASE WHEN Transaction_Status = 'Chargeback' THEN 1 END) AS "Total Bookings Chargeback",
    SUM(CASE WHEN Transaction_Status = 'Chargeback' THEN Expected_Revenue ELSE 0 END) AS "Revenue At Risk",
    ROUND(
        SUM(CASE WHEN Transaction_Status IN ('Failed', 'Chargeback') THEN Expected_Revenue ELSE 0 END) * 100.0 / 
        NULLIF(SUM(Expected_Revenue), 0), 2
    ) AS "Risk Rate Percentage"
FROM View_Analytics_Final
GROUP BY Municipality, Hotel_Type
ORDER BY Risk_Rate_Percentage DESC;
```
|Municipality|Hotel Type|Total Bookings Success|Revenue Confirmed|Total Bookings Failed|Revenue Lost|Total Bookings Chargeback|Revenue At Risk|Risk Rate Percentage|
|------------|----------|----------------------|-----------------|---------------------|------------|-------------------------|---------------|--------------------|
|Orosei|Family Club|292|272314.23|11|9169.14|0|0|3.26|
|Capoliveri|Residence|294|512492.13|8|16632.41|0|0|3.14|
|Gallipoli|Beach Resort|280|258397.46|10|7798.16|0|0|2.93|
|San Candido|Luxury Hotel|291|808385.29|2|4001.53|9|16814.24|2.51|
|Lazise|Boutique Hotel|276|487495.99|3|4142.25|0|0|0.84|
|*NULL*|*NULL*|24|46958.47|0|0|0|0|0.0|

- Despite San Candido hasn't the highest risk rate percentage, it's the only location showing nine chargebacks, worth almost 17000€.
- Orosei and Capoliveri have the highest risk rate percentages, but they only include failed transactions. Therefore, rather than a fraud, it could be due to customers who try to pay for their booking but don't have enough funds in their card, so they got rejected.
- The last row shows those 24 bookings without "Hotel_ID": even if they have all been paid for, it terms of management it's a difficult situation, because they represent 24 occupied rooms in hotels that the system won't recognise.
- The most suspicious insight returned from the query are the 16814.24€ of chargebacks in San Candido. It could be just a coincidence, unfortunate travelers who had to cancel their hoilday. Or it could be that serious scammers aim at luxury hotels like this one, using cloned cards able to bypass the initial control stage, only to be rejected later. This would be a far more dangerous risk than a simple failed transaction.

### Guests' Country of Origin and IP Address

In order to deeper investigate the cause of San Candido's chargebacks, I focused on possible patterns of guests' country of origin and IP address.
Chargeback bookings worh an average of at least 400€ per night, confirming the reason why, in case of scammers, they are inclined in frauding luxury hotels rather than residences. Two customers from the US, Christian Jones and Steven Reed, show NULL values in "Expected_Revenue" and "Nights". They could have tried to scam the booking system but they've eventually been rejected. From the geographic and payment method view points, Russian customers use mainly PayPal and book long stays. It could be an "account takeover" fraud: they log into someone else's PayPal account and book long stay luxury holidays. From the US, instead, they use a mix of credit cards, bank transfers and PayPal. In particular, the use of bank transfers is a possible sympthom of "phishing".

All the IP addresses are different: we can be either in front of 9 unfortunate customers who didn't manage to finalise their bookings, or the same scammer using VPNs, hitting the same hotel and producing the same transaction status (chargeback). Looking at the "Booking_Date" column, I could exclude the option of a rapid attack, since bookings are spread throughout 10 months. A "low and slow" fraud pattern, once or twice a month, dilutes the risk of being discovered.

THe final proof to understand if the nine chargebacks were actually frauds would be to check the IP addresses of these nine suspicious transactions: if they appear also in other bookings, under different customer name and in different location, it means that for sure it's a scam.
```sql
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
```
This CTE returned 9 different IP addresses with 9 different names: a fraud menace still can't be discarded, because there's the chance that the scammer is using dynamic IPs, Proxies or TOR circuits that change every time. Once the chargeback has been received, that specific IP address is discarded. Besides, The fact that these IPs refer only to "chargeback" status, and not to "success" and "failed", pushes towards the direction that these users are not real customers struggling during the booking process. If a real customer has a problem with their booking, they could just send an email or book over the phone.

### Funnel Analysis

When did the hotel loose money? Was it only because of chargebacks, or there was a moment before that in which it was already losing money, maybe due to failed payment? The next query calculated the volume of bookings and revenue for the following steps:
1. Gross Bookings: it counts all the expected revenue;
2. Authorized Payments: it counts the revenue generated by succesful transactions;
3. Net Revenue: what actually remains after considering chargebacks

```sql
SELECT 
    '1. Gross Bookings' AS Step, -- temporary column harcoding
    COUNT(*) AS "Total Transactions",
    SUM(Expected_Revenue) AS "Volume €"
FROM View_Analytics_Final

UNION ALL

SELECT 
    '2. Authorized Payments' AS Step, -- temporary column harcoding
    COUNT(*) AS "Total Transactions",
    ROUND(SUM(Expected_Revenue), 1) AS "Volume €"
FROM View_Analytics_Final
WHERE Transaction_Status = 'Success'

UNION ALL

SELECT 
    '3. Net Revenue' AS Step, -- temporary column harcoding
	(SELECT COUNT(*) FROM View_Analytics_Final WHERE Transaction_Status = 'Success') - 
	(SELECT COUNT(*) FROM View_Analytics_Final WHERE Transaction_Status = 'Chargeback') AS "Total Transactions",
    (SELECT ROUND(SUM(Expected_Revenue), 1) FROM View_Analytics_Final WHERE Transaction_Status = 'Success') - 
	(SELECT ROUND(SUM(Expected_Revenue), 1) FROM View_Analytics_Final WHERE Transaction_Status = 'Chargeback') AS "Volume €";
```

|Step|Total Transactions|Volume €|
|----|------------------|----------|
|1. Gross Bookings|1500|2444601.3|
|2. Authorized Payments|1457|2386043.6|
|3. Net Revenue|1448|2369229.4|

- 97.1% of payments are succesful. It means that the hotel book-and-pay system works fine;
- Between Step 2 and 3 I the possible fraud impact can be seen, causing a loss of €16,814.24;
- The problem is not the quantity of possible frauds or failed payments, but their quality: 11 failed or chargeback transactions out of 302 represent only 3.64% of the total, but they bring with them €20,815.77, 2.5% of the expected revenue.

### Revenue Leakage Analysis

Not only is it important to know how many transactions did't bring any revenue, but also what was their "weight". To demonstrate that the possible fraud was eroding the most rewarding sector (luxury hotels), I calculated the "AOV" - Average Order Value. 

```sql
SELECT 
    Transaction_Status,
    COUNT(*) AS "Total Bookings",
    ROUND(AVG(Expected_Revenue), 1) AS AOV,
    ROUND(SUM(Expected_Revenue), 1) AS "Total Expected Revenue"
FROM View_Analytics_Final
GROUP BY Transaction_Status;
```

|Transaction Status|Total Bookings|AOV|Total Expected Revenue|
|------------------|--------------|---|----------------------|
|Chargeback|9|2402.0|16814.2|
|Failed|34|1304.5|41743.5|
|Success|1457|1731.5|2386043.6|

It turned out that chargebacks worth €2,402 on average, a vaule 39% higher than successful transactions. This could represent a so called "high value fraud pattern": a single fraud worth €2,400 from a luxury hotel is more rewarding than multiple smaller frauds from lower class hotels. Failed transactions are a problem too, way more expensive than chargebacks - €41,743.49 loss against €16,814.24. In this case AOV is lower, around €1,300, meaning that failed transactions are more common in other kinds of hotel, probably in medium-price hotels as in Gallipoli or Orosei. 

## Results and Business Recommendations
While the business focus was primarily on the €16,814.24 lost to chargebacks, the funnel analysis uncovered a much more severe revenue drain: over €41,700 in genuine bookings were lost due to "failed" transaction statuses. The AOV for these failures is low, indicating technical frictions or card limit issues within the family/low-cost segments.

As a conclusion, in both cases (chargeback and failed transactions) the company is losing money, but the approach to a solution is completely different. In San Candido they need to implement stronger identity checks to avoid scammers, while in Gallipoli and Orosei the optimization of the payment gateway would recover three times the amount lost to actual fraud.

## What's next?

In luxury hotels, I would advise implementing a mandatory Strong Customer Authentication (3DS2) for all bookings exceeding €2,000 or stays longer than 5 nights. Managers could also launch every morning the following query, to detect suspicious transactions over the average: 

```sql
SELECT Booking_ID, Customer_Name, Expected_Revenue
FROM View_Analytics_Final
WHERE Municipality = 'San Candido' 
  AND Expected_Revenue > 2000 
  AND Payment_Method IN ('PayPal', 'Bank Transfer');
  ```
  
In general, "failed transaction" reasons need to be reviewed, to reduce technical abandonment rates and improve conversion. Dynamic blacklisting: automate the blocking of IPs from high-risk clusters (RU/US) when attempting bookings on luxury properties.

