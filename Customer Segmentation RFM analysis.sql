--Inspecting Data
SELECT * FROM sales_df;

--SELECT COUNT(*) FROM sales_df;

--Checking unique values for categorical variables
SELECT DISTINCT sales_df.status FROM sales_df; --6 statuses
SELECT DISTINCT year_id FROM sales_df;         --the data is available for years 2003,4 and 5
SELECT DISTINCT productline FROM sales_df;     --7 products
SELECT DISTINCT sales_df.state FROM sales_df;  --the sales are done in 17 states
SELECT DISTINCT country FROM sales_df;         --the sales are done in 19 states
SELECT DISTINCT territory FROM sales_df;       --the sales are done in 3 territories
SELECT DISTINCT dealsize FROM sales_df;        --3 categories for deal size

--Analysis
--Finding revenue and frequency by productline
SELECT productline, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS frequency
FROM sales_df
GROUP BY productline
ORDER BY revenue DESC;
--classic cars is the most successful productline

--Finding revenue and frequency by year
SELECT year_id, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS frequency
FROM sales_df
GROUP BY year_id
ORDER BY revenue DESC;
--2004 was the companys most successful year
--the company has performed poorly in the month of 2005 

--Checking for how many months the company was operational in 2005 
SELECT DISTINCT month_id FROM sales_df
WHERE year_id = '2005'; 
--the company has operated for just 5 months in 2005 hence the revenue is low

SELECT DISTINCT month_id FROM sales_df
WHERE year_id = '2003';

SELECT DISTINCT month_id FROM sales_df
WHERE year_id = '2004';
-- the company was operational for all the 12 months in 2003 and 2004

--Finding revenue and frequency by dealsize
SELECT dealsize, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS frequency
FROM sales_df
GROUP BY dealsize
ORDER BY revenue DESC;
--the company generates way more revenue for Medium sized deals than small and large ones

--Finding revenue and frequency by state
SELECT sales_df.state, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS frequency 
FROM sales_df
WHERE sales_df.state IS NOT NULL
GROUP BY sales_df.state
ORDER BY revenue DESC;

--Finding revenue and frequency by country
SELECT country, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS frequency 
FROM sales_df
GROUP BY country
ORDER BY revenue DESC;
--Comapany earn their highest revenue from USA

--Finding revenue and frequency by territory
SELECT territory, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS frequency 
FROM sales_df
GROUP BY territory
ORDER BY revenue DESC;

--What was the best months for sales in a specific year ? How much was earned in that month ?
SELECT month_id, SUM(sales) AS revenue, COUNT(ordernumber) AS frequency
FROM sales_df
WHERE year_id = '2003'
GROUP BY month_id
ORDER BY revenue DESC , frequency DESC;
--In the year 2003 the company performed really well in the month of november 
--and the frequency of orders for november is almost double that of the 2nd heighest revenue generating month (october)

SELECT month_id, SUM(sales) AS revenue, COUNT(ordernumber) AS frequency
FROM sales_df
WHERE year_id = '2004'
GROUP BY month_id
ORDER BY revenue DESC , frequency DESC;
--In the year 2004 the company performed really well in the month of november 
--and the frequency of orders for november is almost double that of the 2nd heighest revenue generating month (october)

SELECT month_id, SUM(sales) AS revenue, COUNT(ordernumber) AS frequency
FROM sales_df
WHERE year_id = '2005'
GROUP BY month_id
ORDER BY revenue DESC , frequency DESC;
--In the year 2005 may was the highest revenue generating month.

--company performs really well in the month of november
--Checking what products do they sell in the month of november ?

SELECT month_id, productline, SUM(sales) AS revenue, COUNT(ordernumber) AS frequency 
FROM sales_df
WHERE  year_id = '2003' AND month_id = 11
GROUP BY month_id, productline
ORDER BY revenue DESC, frequency DESC;

SELECT month_id, productline, SUM(sales) AS revenue, COUNT(ordernumber) AS frequency 
FROM sales_df
WHERE  year_iD = '2004' AND month_id = 11
GROUP BY month_id, year_id, productline
ORDER BY revenue DESC, frequency DESC;
--The revenue and frequency for sales of Classic Cars is high for the month of november


--Getting the second highest revenue generating productline from each country
--similarly we can get nth revenue generating productline from each country

WITH ranked AS
(
	SELECT country, productline, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS frequency,
	DENSE_RANK() OVER (PARTITION BY country ORDER BY SUM(sales)) AS rank_by_revenue
	FROM sales_df
	GROUP BY productline, country
)
SELECT * FROM ranked 
WHERE rank_by_revenue = 2;


 --RFM analysis
 --recency (how long ago their last purchase was),
 --frequency (how often they purchase), and 
 --monetary value (how much they spend)
 
 --Who is our best customer ?
 --last_order_date_customer = is the date when the customer last placed the order.
 --overall_last_order_date = is the date when the company last received an order.

 --Who are our most recent customers ?
 --recency = shows the number of days it has been since the customer last placed an order.
 --rfm_recency, rfm_frequency, rfm_monetary have values in the range 1 - 4 (1 is lowest and 4 is highest).
 --rfm_recency = closer the last_order_date_customer to the overall_last_order_date higher the cell number
 --rfm_frequency = higher the frequency higher the cell number
 --rfm_monetary = higher the monetary value higher the cell number 


 --Creating a temp table

WITH rfm AS
(
	SELECT 
		customername,
		SUM(sales) AS total_monetary_value,
		AVG(sales) AS avg_monetary_value,
		COUNT(ordernumber) AS frequency,
		MAX(orderdate) AS last_order_date_customer,
		(SELECT MAX(orderdate) FROM sales_df) AS overall_last_order_date,
		DATEDIFF(DD,MAX(orderdate),(SELECT MAX(orderdate) FROM sales_df)) AS recency
	FROM sales_df
	GROUP BY customername
),
rfm_calc AS
( 
	SELECT rfm.*,
		NTILE(4) OVER (ORDER BY recency DESC) AS rfm_recency,
		NTILE(4) OVER (ORDER BY frequency) AS rfm_frequency,
		NTILE(4) OVER (ORDER BY total_monetary_value) AS rfm_monetary
	FROM rfm 
)
SELECT 
	rfm_calc.*,
	CAST(rfm_recency AS varchar) + CAST(rfm_frequency AS varchar) + CAST(rfm_monetary AS varchar) AS rfm_cell_string
INTO #rfm_c
FROM rfm_calc;

--Creating an rfm indicator
SELECT customername, rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string IN (111,112,121,122,211,212,221,213,222,223,232,113,131,114,141,123,132) THEN 'lost_customers'    --lost customers
		WHEN rfm_cell_string IN (133,134,143,144,234,233,244,323,333,334,343,344) THEN 'highly_spending customers' --Big spenders who haven't purchased lately
		WHEN rfm_cell_string IN (311,312,313,314,411,412,413,414) THEN 'new customers'
		WHEN rfm_cell_string IN (322,321,332,422,423,421,432) THEN 'active'
		WHEN rfm_cell_string IN (431,432,433,434,443,444) THEN 'loyal'
	END AS rfm_indicator
FROM #rfm_c;


--What products are most often sold together ?
--SELECT * FROM sales_df WHERE ordernumber = '10220';
--Multiple purchases by a single customer are under same ordernumber

--The CTE blocks gives us ordernumber and product code based on the freq provided 

WITH shipped_products
 AS
( 
	SELECT ordernumber, COUNT(*) as freq
	FROM sales_df
	WHERE status = 'Shipped'
	GROUP BY  ordernumber
),
product_sold_together AS 
(
SELECT DISTINCT ordernumber, STUFF(
	(SELECT ',' + productcode
	FROM sales_df as pc
	WHERE ordernumber IN (SELECT ordernumber FROM shipped_products
							WHERE freq = 2)  --freq = 2 for which 2 products are sold together \\y for 3 products we will have freq = 3
	AND pc.ordernumber = st.ordernumber
	FOR XML PATH ('')
	),1,1,'') AS product_codes
FROM sales_df AS st
)
SELECT product_codes, COUNT(product_codes) AS sold_together_frequency
FROM product_sold_together
WHERE product_codes IS NOT NULL
GROUP BY product_codes
ORDER BY sold_together_frequency DESC;
