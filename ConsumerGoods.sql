use cgood;

/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/


SELECT  
  DISTINCT(market),
  customer,
  region  
FROM 
  dbo.dim_customer 
WHERE 
  customer = 'Atliq Exclusive' 
  AND region = 'APAC';



/* 2. What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg*/


SELECT 
    COUNT(
			DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END
		 ) AS unique_products_2020,

    COUNT(
			DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END
		 ) AS unique_products_2021,

    ROUND((
	COUNT(
			DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END)- 
    COUNT(
			DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END)) 

	/ NULLIF(COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END), 0) * 100, 2) AS percentage_chg

FROM fact_sales_monthly
WHERE fiscal_year IN (2020, 2021);



/* 3. Provide a report with all the unique product counts for each segment and sort them
in descending order of product counts. The final output contains 2 fields, segment and product_count */


SELECT 
	segment, 
	count(product) as product_count 
FROM 
	dbo.dim_product 
GROUP BY 
	segment 
ORDER BY 
	product_count DESC;



/* 4. Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, product_code product manufacturing_cost */


SELECT 
	mc.product_code, 
	p.product, 
	mc.manufacturing_cost 
FROM 
	fact_manufacturing_cost AS mc 
	LEFT JOIN dim_product AS p 
	ON mc.product_code = p.product_code 
WHERE 
	mc.manufacturing_cost = (SELECT MIN(manufacturing_cost) 
								FROM fact_manufacturing_cost) 
 OR mc.manufacturing_cost = (SELECT MAX(manufacturing_cost) 
								FROM fact_manufacturing_cost) 
ORDER BY 
  manufacturing_cost DESC;



/* 5. Generate a report which contains the top 5 customers who received
an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
The final output contains these fields, customer_code customer average_discount_percentage	*/


SELECT TOP 5
	fpid.customer_code, 
	c.customer, 
	CAST(
		ROUND(AVG(fpid.pre_invoice_discount_pct) * 100, 2) AS decimal(10, 2)
		) AS average_discount_percentage
FROM 
	dbo.fact_pre_invoice_deductions AS fpid
JOIN dbo.dim_customer AS c 
ON 
	fpid.customer_code = c.customer_code
WHERE 
	fpid.fiscal_year = 2021 AND c.market = 'India'
GROUP BY 
	fpid.customer_code, c.customer
ORDER BY
	average_discount_percentage DESC;


/*6. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .
This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: Month Year Gross sales Amount */


SELECT 
	DATENAME(month, s.date) as Month, 
	YEAR(s.date) as Year,
	ROUND(
		SUM(g.gross_price * s.sold_quantity)/1000000,2
		) AS Gross_sales_Amount_mln

FROM 
	fact_sales_monthly AS s
	JOIN fact_gross_price AS g 
ON 
	g.fiscal_year = s.fiscal_year and s.product_code = g.product_code 
	JOIN dim_customer AS c
ON 
	c.customer_code = s.customer_code
WHERE 
	c.customer = 'Atliq Exclusive' 
GROUP BY 
	DATENAME(month, s.date), YEAR(s.date);



/* 7. In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity*/


SELECT
	q.quarter_name AS Quarter,
	COALESCE(SUM(fs.sold_quantity), 0) AS total_sold_quantity
FROM
	(
	SELECT 'Q1' AS quarter_name
		UNION SELECT 'Q2'
		UNION SELECT 'Q3'
		UNION SELECT 'Q4'
	) AS q
	LEFT JOIN fact_sales_monthly fs 
	ON 
		q.quarter_name = 'Q' + CAST((MONTH(fs.date) + 2) / 3 AS VARCHAR) AND fs.fiscal_year = 2020
GROUP BY
	q.quarter_name
ORDER BY
	total_sold_quantity DESC



/*8. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields, channel gross_sales_mln percentage*/


SELECT
	dc.channel,
	SUM(fgp.gross_price) / 1000000 AS gross_sales_mln,
	(SUM(fgp.gross_price) / SUM(SUM(fgp.gross_price)) OVER ()) * 100 AS percentage
FROM
	fact_sales_monthly AS fsm
	JOIN dim_customer dc 
ON 
	fsm.customer_code = dc.customer_code
	JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
WHERE
	fsm.fiscal_year = 2021
GROUP BY
	dc.channel
ORDER BY
	gross_sales_mln DESC;


