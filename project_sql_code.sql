-- Codebasics SQL Challenge


-- _____________________________________Request_1_____________________________________________
-- Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.   

SELECT
	DISTINCT market
FROM 
	dim_customer
WHERE 
	customer = "Atliq Exclusive"
    AND region = "APAC";   




-- _____________________________________Request_2_____________________________________________
-- What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

WITH unique_products AS (
	SELECT
		SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END) AS unique_products_2020,
		SUM(CASE WHEN fiscal_year = 2021 THEN 1 ELSE 0 END) AS unique_products_2021
	FROM
		fact_gross_price
)

SELECT 
	unique_products_2020,
    unique_products_2021,
    ROUND((unique_products_2021 - unique_products_2020) *100 / unique_products_2020, 2) AS percentage_chg
FROM 
	unique_products;




-- _____________________________________Request_3_____________________________________________
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

SELECT
	segment,
    COUNT( DISTINCT product_code ) AS product_count
FROM
	dim_product
GROUP BY 
	segment
ORDER BY
	product_count DESC;




-- _____________________________________Request_4_____________________________________________
-- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

WITH segment_products AS (
	SELECT
		dp.segment,
		SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END) AS product_count_2020,
		SUM(CASE WHEN fiscal_year = 2021 THEN 1 ELSE 0 END) AS product_count_2021
	FROM
		dim_product dp
	JOIN 
		fact_gross_price fg
		ON fg.product_code = dp.product_code
	GROUP BY
		segment
)

SELECT 
	segment,
    product_count_2020,
    product_count_2021,
    ( product_count_2021 - product_count_2020 ) AS difference
FROM
	segment_products
ORDER BY
	difference DESC;




-- _____________________________________Request_5_____________________________________________
-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

WITH costs AS (
	SELECT
		fm.product_code,
		dp.product,
		fm.manufacturing_cost
	FROM
		fact_manufacturing_cost fm
	JOIN 
		dim_product dp
		ON dp.product_code = fm.product_code
)

(
	SELECT
		product_code,
		product,
		manufacturing_cost
	FROM
		costs
	ORDER BY 
		manufacturing_cost DESC
		LIMIT 1
)
	UNION 
(
	SELECT
		product_code,
		product,
		manufacturing_cost
	FROM
		costs
	ORDER BY 
		manufacturing_cost
		LIMIT 1
);




-- _____________________________________Request_6_____________________________________________
-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

SELECT
	dc.customer_code,
    dc.customer,
    fp.pre_invoice_discount_pct
FROM
	dim_customer dc
JOIN
	fact_pre_invoice_deductions fp
	ON dc.customer_code = fp.customer_code
WHERE
	fiscal_year = 2021
    AND market = "India"
ORDER BY 
	fp.pre_invoice_discount_pct DESC
	LIMIT 5;




-- _____________________________________Request_7_____________________________________________
-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount 

WITH monthly_sales AS (
	SELECT
		dc.customer,
		MONTHNAME(fs.`date`) as Month,
		fs.fiscal_year AS Year,
		fs.sold_quantity,
		fg.gross_price
		
	FROM
		dim_customer dc
	JOIN fact_sales_monthly fs
		ON dc.customer_code = fs.customer_code
	JOIN 
		fact_gross_price fg
		ON fs.product_code = fg.product_code
		AND fs.fiscal_year = fg.fiscal_year
)

SELECT
	Month,
    Year,
    SUM( sold_quantity * gross_price ) AS gross_sales_amount
FROM
	monthly_sales
WHERE
	customer = "Atliq Exclusive"
GROUP BY
	Month, Year;




-- _____________________________________Request_8_____________________________________________
-- In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

SELECT
	CONCAT("Q", QUARTER(date)) as Qtr,
    SUM( sold_quantity ) AS total_sold_quantity
FROM 
	fact_sales_monthly
WHERE
	fiscal_year = 2020
GROUP BY 
	Qtr
ORDER BY 
	total_sold_quantity DESC
LIMIT 1;




-- _____________________________________Request_9_____________________________________________
-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

WITH channel_sales AS (
	SELECT
		dc.channel,
		SUM( fs.sold_quantity * fg.gross_price ) AS gross_sales
	FROM
		dim_customer dc
	JOIN
		fact_sales_monthly fs
		ON fs.customer_code = dc.customer_code
	JOIN
		fact_gross_price fg
		ON fg.product_code = fs.product_code
		AND fg.fiscal_year = fs.fiscal_year
	WHERE 
		fg.fiscal_year = 2021
	GROUP BY 
		dc.channel
),
total_sales AS (
	SELECT
		SUM( gross_sales ) AS total_gross_sales
	FROM channel_sales
)

SELECT
	channel,
    gross_sales,
    ROUND( ( gross_sales * 100 / total_gross_sales ), 2 ) AS percentage_contribution
FROM 
	channel_sales
JOIN 
	total_sales
ORDER BY
	gross_sales DESC;




-- _____________________________________Request_10_____________________________________________
-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order

WITH divisions AS (
	SELECT
		dp.division,
		dp.product_code,
		dp.product,
		dp.variant,
		SUM( fs.sold_quantity ) AS total_quantity_sold
	FROM
		dim_product dp
	JOIN 
		fact_sales_monthly fs
		ON dp.product_code = fs.product_code
	WHERE
		fiscal_year = 2021
	GROUP BY 
		dp.division, 
		dp.product_code,
		dp.product,
		dp.variant
)
, ranks AS (
	SELECT
		*, 
		ROW_NUMBER() OVER(
			PARTITION BY division
			ORDER BY total_quantity_sold DESC
		) AS rank_order
	FROM
		divisions
)

SELECT
	*
FROM 
	ranks
WHERE
	rank_order <=3;



-- _____________________________________END_____________________________________________
















	

























    
    
    
    
    
    
    
    
    
    
    

	

























    










