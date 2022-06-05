use db_SQLCaseStudies

--1. List all the states in which we have customers who have bought a mobile from 2005 till today.
SELECT DISTINCT( t2.state )
FROM   fact_transactions t1
       LEFT JOIN dim_location t2
              ON t1.idlocation = t2.idlocation
WHERE  Year(t1.date) >= 2005

--2. What state in the US is buying more "Samsung" cellphones?
SELECT t2.state,
       Sum(t1.quantity) AS Total_Samsung_Sold
FROM   fact_transactions t1
       JOIN dim_location t2
         ON t1.idlocation = t2.idlocation
       JOIN dim_model t3
         ON t1.idmodel = t3.idmodel
       JOIN dim_manufacturer t4
         ON t3.idmanufacturer = t4.idmanufacturer
WHERE  t4.manufacturer_name = 'Samsung'
       AND t2.country = 'US'
GROUP  BY t2.state
ORDER  BY Sum(t1.quantity) DESC 

--3. Show the number of transactions for each model per zip code per state.
SELECT Count(*) Num_of_Transaction,
       t1.idmodel,
       t2.zipcode,
       t2.state
FROM   fact_transactions t1
       LEFT JOIN dim_location t2
              ON t1.idlocation = t2.idlocation
GROUP  BY t1.idmodel,
          t2.zipcode,
          t2.state
ORDER  BY t2.state 

--4. Show the cheapest cellphone.
SELECT TOP 1 t3.manufacturer_name,
             t2.model_name,
             t2.idmodel,
             t1.totalprice
FROM   fact_transactions t1
       INNER JOIN dim_model t2
               ON t1.idmodel = t2.idmodel
       INNER JOIN dim_manufacturer t3
               ON t3.idmanufacturer = t2.idmanufacturer
ORDER  BY totalprice ASC 

--5. Find out the average price for each model in the top 5 manufacturers in terms of sales quality and oder by average price.
SELECT t3.manufacturer_name,
       t2.model_name,
       Sum(totalprice) / Sum(quantity) AS Avg_Price
FROM   fact_transactions t1
       LEFT JOIN dim_model t2
              ON t1.idmodel = t2.idmodel
       LEFT JOIN dim_manufacturer t3
              ON t2.idmanufacturer = t3.idmanufacturer
WHERE  t3.manufacturer_name IN (SELECT TOP 5 t3.manufacturer_name
                                FROM   fact_transactions t1
                                       LEFT JOIN dim_model t2
                                              ON t1.idmodel = t2.idmodel
                                       LEFT JOIN dim_manufacturer t3
                                              ON
                                       t2.idmanufacturer = t3.idmanufacturer
                                GROUP  BY t3.manufacturer_name
                                ORDER  BY Sum(t1.quantity) DESC)
GROUP  BY t2.model_name,
          t3.manufacturer_name
ORDER  BY Sum(totalprice) / Sum(quantity) 

--6. List the name of the customers and the average amount spent in 2009, where the average is higher than 500.
SELECT Avg(t1.totalprice),
       t2.customer_name
FROM   fact_transactions t1
       LEFT JOIN dim_customer t2
              ON t1.idcustomer = t2.idcustomer
WHERE  Year(t1.date) = '2009'
GROUP  BY t2.customer_name
HAVING Avg(t1.totalprice) > 500
ORDER  BY Avg(t1.totalprice) DESC

--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010.
SELECT *
FROM   (SELECT TOP 5 t1.idmodel --,sum(t1.quantity)
        FROM   fact_transactions t1
        WHERE  Year(date) = 2008
        GROUP  BY t1.idmodel
        ORDER  BY Sum(t1.quantity) DESC) AS x
INTERSECT
SELECT *
FROM   (SELECT TOP 5 t1.idmodel --,sum(t1.quantity) 
        FROM   fact_transactions t1
        WHERE  Year(date) = 2009
        GROUP  BY t1.idmodel
        ORDER  BY Sum(t1.quantity) DESC) AS u
INTERSECT
SELECT *
FROM   (SELECT TOP 5 t1.idmodel--,sum(t1.quantity) 
        FROM   fact_transactions t1
        WHERE  Year(date) = 2010
        GROUP  BY t1.idmodel
        ORDER  BY Sum(t1.quantity) DESC) AS t 


--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer wih the second top sales in th year 2010.
SELECT tt1.manufacturer_name AS Second_largest_2009,
       tt2.manufacturer_name AS Second_largest_2010
FROM   (SELECT t3.manufacturer_name,
               Sum(t1.totalprice)                    AS total_sales_2009,
               Row_number()
                 OVER(
                   ORDER BY Sum(t1.totalprice) DESC) AS Ranks
        FROM   fact_transactions t1
               INNER JOIN dim_model t2
                       ON t1.idmodel = t2.idmodel
               INNER JOIN dim_manufacturer t3
                       ON t2.idmanufacturer = t3.idmanufacturer
        WHERE  Year(date) = 2009
        GROUP  BY t3.manufacturer_name) AS tt1,
       (SELECT t3.manufacturer_name,
               Sum(t1.totalprice)                    AS total_sales_2010,
               Row_number()
                 OVER(
                   ORDER BY Sum(t1.totalprice) DESC) AS Ranks
        FROM   fact_transactions t1
               INNER JOIN dim_model t2
                       ON t1.idmodel = t2.idmodel
               INNER JOIN dim_manufacturer t3
                       ON t2.idmanufacturer = t3.idmanufacturer
        WHERE  Year(date) = 2010
        GROUP  BY t3.manufacturer_name) AS tt2
WHERE  tt1.ranks = 2
       AND tt2.ranks = 2 

--9. Show the manufacturer that sold cellphones in 2010 but not in 2009.
SELECT DISTINCT( t3.manufacturer_name )
FROM   fact_transactions t1
       INNER JOIN dim_model t2
               ON t1.idmodel = t2.idmodel
       INNER JOIN dim_manufacturer t3
               ON t2.idmanufacturer = t3.idmanufacturer
WHERE  Year(date) = 2010
       AND t2.idmanufacturer NOT IN (SELECT DISTINCT( t2.idmanufacturer )
                                     FROM   fact_transactions t1
                                            INNER JOIN dim_model t2
                                                    ON t1.idmodel = t2.idmodel
                                     WHERE  Year(date) = 2009) 

--10. Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
SELECT TOP 100 t2.customer_name,
               Avg(t1.totalprice) AS AVG_Spend,
               Avg(t1.quantity)   AS AVG_Qty,
               Year(t1.date)      AS In_Year
FROM   fact_transactions t1
       LEFT JOIN dim_customer t2
              ON t1.idcustomer = t2.idcustomer
GROUP  BY Year(t1.date),
          t2.customer_name
ORDER  BY t2.customer_name ASC,
          Year(t1.date)ASC 
