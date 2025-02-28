use amazon_db;
select * from category;
select * from customers;
select * from inventory;
select * from order_items;
select * from orders;
select * from payments;
select distinct payment_status from payments;
select * from products;
select * from sellers;
select * from shippings;
select * from orders;

select * from orders where order_id = 6747;

select * from payments;

select * from payments where order_id = 6747;

select * from shippings where return_date is not null;

select * from order_items;
-- ---------------------------------------
-- amazon business problems
-- advanced sql
-- ---------------------------------------
/*
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.
*/
-- join order_item -- order -- product
-- group by product id
-- total sale
-- top 10

select * from order_items;
