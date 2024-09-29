-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
    product_name || ', ' || 
    COALESCE(product_size, '') || ' (' || 
    COALESCE(product_qty_type, 'unit') || ')' AS product_details
FROM product;



--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

-- Using ROW_NUMBER() to number each customer's visits to the market
SELECT customer_id, market_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date) AS visit_number
FROM customer_purchases;

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

-- Reverse the visit numbering
WITH ranked_visits AS (
    SELECT customer_id, market_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS reverse_visit_number
    FROM customer_purchases
)
-- Filter to get only the most recent visit
SELECT customer_id, market_date
FROM ranked_visits
WHERE reverse_visit_number = 1;


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

-- Count how many different times each customer has purchased the same product
SELECT customer_id, product_id, market_date,
       COUNT(product_id) OVER (PARTITION BY customer_id, product_id ORDER BY market_date) AS purchase_count
FROM customer_purchases;



-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

-- We're selecting the product_name and extracting the description part after the hyphen
SELECT product_name,
       -- Find the position of the hyphen in the product_name, then get the substring starting after the hyphen (position + 2)
       -- TRIM removes any extra spaces around the description to make it clean
       TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 2)) AS description
FROM product
-- Only include rows where there's actually a hyphen in the product_name
WHERE INSTR(product_name, '-') > 0;


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

-- Select product names where product_size contains a number
SELECT product_name, product_size
FROM product
WHERE product_size REGEXP '[0-9]';



-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

-- Step 1: Create a CTE to find total sales grouped by market dates
WITH sales_by_date AS (
    SELECT market_date, SUM(quantity * cost_to_customer_per_qty) AS total_sales
    FROM customer_purchases
    GROUP BY market_date
),

-- Step 2: Create another CTE with rank to find the best and worst sales days
ranked_sales AS (
    SELECT market_date, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS best_rank,
           RANK() OVER (ORDER BY total_sales ASC) AS worst_rank
    FROM sales_by_date
)

-- Step 3: Use UNION to get the highest and lowest sales days
SELECT market_date, total_sales, 'Best Day' AS label
FROM ranked_sales
WHERE best_rank = 1

UNION

SELECT market_date, total_sales, 'Worst Day' AS label
FROM ranked_sales
WHERE worst_rank = 1;




