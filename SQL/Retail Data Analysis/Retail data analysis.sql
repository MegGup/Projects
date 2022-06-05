--DATA PREP

use basic_sql_case_study

--1. What is the total number of rows in each of the 3 tables in the database?
SELECT *
FROM   (SELECT 'TRANSACTIONS' AS TABLE_NAME,
               Count(*)       AS NO_OF_RECORDS
        FROM   transactions
        UNION ALL
        SELECT 'PROD_CAT_INFO' AS TABLE_NAME,
               Count(*)        AS NO_OF_RECORDS
        FROM   prod_cat_info
        UNION ALL
        SELECT 'CUSTOMER' AS TABLE_NAME,
               Count(*)   AS NO_OF_RECORDS
        FROM   customer) TBL 

--2. What is the total number of trasactions that have a return
SELECT Count(transaction_id)
FROM   transactions
WHERE  qty < 0 

/*3. As you would have noticed, the dates provided across the data set are not in correct format.
As first steps, please convert the date variables into valid date format. */
SELECT CONVERT(DATETIME, tran_date, 103)
FROM   transactions

SELECT CONVERT(DATETIME, dob, 103)
FROM   customer 

/*-4. What is the time range of the transaction data available for analysis?
Show the output in number of days, months and years simultaneously in different columns.*/
SELECT Datediff(day, Min(CONVERT(DATETIME, tran_date, 103)), 
				Max(CONVERT(DATETIME, tran_date, 103)))        AS range_in_days,
       Datediff(month, Min(CONVERT(DATETIME, tran_date, 103)), 
				Max(CONVERT(DATETIME, tran_date, 103)))        AS range_in_months,
       Datediff(year, Min(CONVERT(DATETIME, tran_date, 103)), 
				Max(CONVERT(DATETIME, tran_date, 103)))        AS range_in_years
FROM   transactions 

--5. Which product category does the sub-categoy "DIY" belong to?
SELECT prod_cat
FROM   prod_cat_info
WHERE  prod_subcat = 'DIY' 


/*DATA ANALYSIS

1. Which channel is the most frequesntly used for transactions?*/
SELECT TOP 1 store_type            AS channel,
             Count(transaction_id) AS count_of_transactions
FROM   transactions
GROUP  BY store_type
ORDER  BY Count(transaction_id) DESC 

--2. What is the count of male and female customers in the database?
SELECT CASE
         WHEN gender = 'M' THEN 'Male'
         WHEN gender = 'F' THEN 'Female'
       END           AS Genders,
       Count(gender) AS Count_of_Genders
FROM   customer
WHERE  gender IN ( 'M', 'F' )
GROUP  BY gender 

--3. From which city do we have the maximum numbers of customers and how many? 
SELECT TOP 1 city_code,
             Count(city_code)
FROM   customer
GROUP  BY city_code
ORDER  BY Count(city_code) DESC 

--4. How many sub categories are there under thebooks category?
SELECT Count(prod_subcat)
FROM   prod_cat_info
WHERE  prod_cat = 'Books' 

--5. What is the maximum quatity of products ever ordered?
SELECT Max(qty)
FROM   transactions 

--6. WHat is the net total revenue generated in categories Electronics and Books?
SELECT Sum(t1.total_amt) AS Total_Revenue,
       t2.prod_cat       AS Category
FROM   transactions t1
       INNER JOIN prod_cat_info t2
               ON t1.prod_cat_code = t2.prod_cat_code
                  AND t1.prod_subcat_code = t2.prod_sub_cat_code
WHERE  t2.prod_cat IN ( 'Electronics', 'Books' )
GROUP  BY t2.prod_cat 

--7. How many customers have >10 transactions with us, excluding returns?
SELECT Count(*) AS Count_of_Customers
FROM   (SELECT Count(transaction_id) AS No_of_Transactions,
               cust_id
        FROM   transactions t1
        WHERE  qty > 0
        GROUP  BY cust_id
        HAVING Count(transaction_id) > 10) AS t4 

--8. What is the combined revenue earned from the Electronics and Clothing categories, from Flagship stores?
SELECT Sum(t1.total_amt) AS Total_Revenue
FROM   transactions t1
       INNER JOIN prod_cat_info t2
               ON t1.prod_cat_code = t2.prod_cat_code
                  AND t1.prod_subcat_code = t2.prod_sub_cat_code
WHERE  t2.prod_cat IN ( 'Electronics', 'Clothing' )
       AND t1.store_type = 'Flagship store' 

/*9. What is the total revenue generated from Male customers in Electronics category?
Output should display total revenue by prod sub-cat.*/
SELECT Sum(t1.total_amt),
       t2.prod_subcat
FROM   transactions t1
       INNER JOIN prod_cat_info t2
               ON t1.prod_cat_code = t2.prod_cat_code
                  AND t1.prod_subcat_code = t2.prod_sub_cat_code
       INNER JOIN customer t3
               ON t1.cust_id = t3.customer_id
WHERE  t2.prod_cat = 'Electronics'
       AND t3.gender = 'M'
GROUP  BY t2.prod_subcat 

--10. What is the precentage of sales and returns by product sub category; display only top 5 sub categories in terms of sale.
SELECT z.p,
       z.sale_amt / ( z.sale_amt - y.return_amt ) * 100    AS 'Sale%',
       -y.return_amt / ( z.sale_amt - y.return_amt ) * 100 AS 'Return%'
FROM   (SELECT t1.prod_subcat_code AS p,
               Sum(qty)            AS Sale_amt
        FROM   transactions t1
        WHERE  qty > 0
        GROUP  BY t1.prod_subcat_code) AS z
       INNER JOIN (SELECT t1.prod_subcat_code AS p,
                          Sum(qty)            AS Return_amt
                   FROM   transactions t1
                   WHERE  qty < 0
                   GROUP  BY t1.prod_subcat_code) AS y
               ON z.p = y.p
                  AND z.p IN (SELECT TOP 5 t1.prod_subcat_code
                              FROM   transactions t1
                              GROUP  BY t1.prod_subcat_code
                              ORDER  BY Sum(total_amt) DESC) 


/*11. For all customers aged between 25 to 35 years, find what is the net total revenue generated by these consumers in 
the last 30 days of transactions from max transaction date available from the data.*/
SELECT Sum(t1.total_amt) total_revenue_gen
FROM   transactions t1
       LEFT JOIN customer t2
              ON t1.cust_id = t2.customer_id
WHERE  Datediff(year, ( CONVERT(DATETIME, t2.dob, 103) ), Getdate()) < 35
       AND Datediff(year, ( CONVERT(DATETIME, t2.dob, 103) ), Getdate()) >= 25
       AND Datediff(day, CONVERT(DATETIME, t1.tran_date, 103),(SELECT Max(CONVERT(DATETIME, tran_date,103)) FROM transactions))<= 30 

--12. Which product category has seen the max value of returns in the last 3 months of transactions.
SELECT TOP 1 t2.prod_cat--, sum(t1.total_amt)
FROM   transactions t1
       LEFT JOIN prod_cat_info t2
              ON t1.prod_cat_code = t2.prod_cat_code
                 AND t1.prod_subcat_code = t2.prod_sub_cat_code
WHERE  Datediff(month, CONVERT(DATETIME, tran_date, 103),
       (SELECT Max(
              CONVERT(DATETIME,
              tran_date, 103))
        FROM   transactions)) <= 3
       AND qty < 0
GROUP  BY t2.prod_cat
ORDER  BY Sum(t1.total_amt) ASC 

--13. Which store type sells the maximum products; by value of sales amount and by quantity sold.
SELECT TOP 1 Sum(total_amt) Total_Revenue,
             Sum(qty)       Sum_of_Qty,
             store_type
FROM   transactions
GROUP  BY store_type
ORDER  BY Sum(total_amt) DESC,
          Sum(qty) DESC 

--14. What are the categories for which average revenue is above the overall average.
SELECT Avg(total_amt),
       t2.prod_cat
FROM   transactions t1
       INNER JOIN prod_cat_info t2
               ON t1.prod_cat_code = t2.prod_cat_code
                  AND t1.prod_subcat_code = t2.prod_sub_cat_code
GROUP  BY prod_cat
HAVING Avg(total_amt) > (SELECT Avg(total_amt)
                         FROM   transactions) 

--15. Find the average and total revenue by each sub category for the categories which are amoung top 5 categories in terms of quantity sold.
SELECT Avg(t1.total_amt) AS Avg_Revenue,
       Sum(t1.total_amt) AS Total_Revenue,
       t2.prod_subcat,
       t2.prod_cat
FROM   transactions t1
       INNER JOIN prod_cat_info t2
               ON t1.prod_cat_code = t2.prod_cat_code
                  AND t1.prod_subcat_code = t2.prod_sub_cat_code
WHERE  t1.prod_cat_code IN (SELECT TOP 5 prod_cat_code
                            FROM   transactions
                            GROUP  BY prod_cat_code
                            ORDER  BY Sum(qty) DESC)
GROUP  BY t2.prod_subcat,
          t2.prod_cat
ORDER  BY t2.prod_cat 