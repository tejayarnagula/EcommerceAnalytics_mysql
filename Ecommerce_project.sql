## create ecommerce data base
create database	ecommerce;

# Use ecommerce data base
use ecommerce;

##### Create Tables to import Data #######
## olist_customers_dataset Table
create table olist_customers_dataset
( customer_id char (32) primary key,
  customer_unique_id char(32),
  customer_zip_code_prefix int,
  customer_city varchar(40),
  customer_state char(2));
  select * from olist_customers_dataset;

## Import Data from the csv file into the Table

load data infile "olist_customers_dataset.csv" into table  olist_customers_dataset
fields terminated by ','
ignore 1 lines;

## Other Tables were crearted using the schema ##

## 1. Total Customers
SELECT 
    COUNT(*) 'Total Customers'
FROM
    olist_customers_dataset;

## 2. Cities having top 5 number sellers
SELECT 
    seller_city, COUNT(seller_id) Sellers_num
FROM
    olist_sellers_dataset
GROUP BY seller_city
ORDER BY COUNT(seller_id) DESC
LIMIT 5;

## 3. Total Orders in Current year
SELECT 
    YEAR(order_purchase_timestamp) Current_year,
    COUNT(order_id) Total_Orders
FROM
    olist_orders_dataset
WHERE
    YEAR(order_purchase_timestamp) = (SELECT 
            MAX(YEAR(order_purchase_timestamp))
        FROM
            olist_orders_dataset)
GROUP BY YEAR(order_purchase_timestamp);

## 4. Total Payment in current year 
SELECT 
    YEAR(order_purchase_timestamp) Current_year , 
    concat(round(SUM(payment_value)/1000000,2),' M') Total_Payment
FROM
    olist_order_payments_dataset
        INNER JOIN
    olist_orders_dataset ON olist_order_payments_dataset.order_id = olist_orders_dataset.order_id
WHERE
    YEAR(order_purchase_timestamp) = (SELECT 
            MAX(YEAR(order_purchase_timestamp))
        FROM
            olist_orders_dataset)
GROUP BY YEAR(order_purchase_timestamp);

## 5. Top 10 Cities with Highest Customer Number
SELECT 
    customer_city AS 'Top 10 City',
    COUNT(customer_id) AS 'Customers Num'
FROM
    olist_customers_dataset
GROUP BY customer_city
ORDER BY COUNT(customer_id) DESC
LIMIT 10;

## 6. Top 10 Cities based on payments
SELECT 
    olist_customers_dataset.customer_city AS 'Top 10 City',
    CONCAT(ROUND(SUM(olist_order_payments_dataset.payment_value) / 1000000,
                    2),
            ' M') 'Payment Value'
FROM
    olist_customers_dataset
        INNER JOIN
    olist_orders_dataset ON olist_customers_dataset.customer_id = olist_orders_dataset.customer_id
        INNER JOIN
    olist_order_payments_dataset ON olist_orders_dataset.order_id = olist_order_payments_dataset.order_id
GROUP BY olist_customers_dataset.customer_city
ORDER BY SUM(olist_order_payments_dataset.payment_value) DESC
LIMIT 10;

## 7. Select weekday and weekend payment 
select case when dayofweek(order_purchase_timestamp) in (2,3,4,5,6) then "Weekday"
            when dayofweek(order_purchase_timestamp) in (1,7) then "Weekend"
            end Order_Time,
	        count(*) as Orders,
            sum(olist_order_payments_dataset.payment_value)
       from olist_orders_dataset
       inner join olist_order_payments_dataset
       on olist_order_payments_dataset.order_id = olist_order_payments_dataset.order_id
       group by Order_Time;
       
## 8. Quarterly Change in number of orders
select case when month(order_purchase_timestamp) in (1,2,3) then "Quarter 1"
            when month(order_purchase_timestamp) in (4,5,6) then "Quarter 2"
            when month(order_purchase_timestamp) in (7,8,9) then "Quarter 3"
            when month(order_purchase_timestamp) in (10,11,12) then "Quarter 4"
            END Quarter_Num,
            year(order_purchase_timestamp) Order_Year,
            count(order_id) Total_Order
            from olist_orders_dataset
            group by Quarter_Num,Order_Year
            order by Order_Year,Quarter_Num;

## 9. Product Category Preference of Customers (Top 10)
select * from product_category_name_translation ;
SELECT 
    product_category_name_translation.product_category_name_english Category,
    COUNT(olist_order_items_dataset.order_id) Total_Orders,
    CONCAT(ROUND(SUM(olist_order_items_dataset.price) / 1000000,
                    2),
            ' M') Total_sale
FROM
    olist_order_items_dataset
        INNER JOIN
    olist_products_dataset ON olist_products_dataset.product_id = olist_order_items_dataset.product_id
        INNER JOIN
    product_category_name_translation ON product_category_name_translation.ï»¿product_category_name = olist_products_dataset.product_category_name
GROUP BY (product_category_name_translation.product_category_name_english)
ORDER BY COUNT(olist_order_items_dataset.order_id) DESC
LIMIT 10;

## 10. Prefered Payment mode
SELECT 
    payment_type,
    CONCAT(ROUND((SUM(payment_value) / 1000000), 2),
            ' M') Total_Payment
FROM
    olist_order_payments_dataset
GROUP BY payment_type;

## 11. Top 10 Product Category With Total Review and Average Review Score
SELECT 
    olist_products_dataset.product_category_name,
    COUNT(olist_order_reviews_dataset.review_id) Total_Reviews, # anything inside count will give total number of rows in that row
    round(avg(olist_order_reviews_dataset.review_score),2) Avg_Review
FROM
    olist_order_reviews_dataset
    inner join
    olist_order_items_dataset
    on olist_order_reviews_dataset.order_id = olist_order_items_dataset.order_id
    inner join
    olist_products_dataset
    on
    olist_order_items_dataset.product_id = olist_products_dataset.product_id
GROUP BY (olist_products_dataset.product_category_name)
ORDER BY Total_Reviews DESC
limit 10;

## 12. Review Score and Shipping Days
select olist_order_reviews_dataset.review_score Review_Score,
       round(avg(datediff(order_delivered_customer_date,order_purchase_timestamp))) avg_delivery_days
       from olist_orders_dataset
       inner join olist_order_reviews_dataset
       on olist_order_reviews_dataset.order_id = olist_orders_dataset.order_id
group by Review_Score 
order by Review_Score desc; 

## 13. Review Scores and Number of Orders
SELECT 
    review_score Review_Score, COUNT(order_id) Num_Orders
FROM
    olist_order_reviews_dataset
GROUP BY Review_Score
ORDER BY Review_Score DESC; 

## 14. Total Order and Payment Trend Over Month
SELECT 
    MONTHNAME(order_purchase_timestamp) Month_Name,
    COUNT(olist_order_payments_dataset.order_id) Order_Num,
    CONCAT(ROUND(SUM(olist_order_payments_dataset.payment_value) / 1000000,
                    2),
            ' M') Payment_Val
FROM
    olist_order_payments_dataset
        INNER JOIN
    olist_orders_dataset ON olist_orders_dataset.order_id = olist_order_payments_dataset.order_id
GROUP BY MONTHNAME(order_purchase_timestamp)
ORDER BY COUNT(olist_order_payments_dataset.order_id) DESC;
