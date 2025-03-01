# **Amazon USA Sales Analysis Project**
## **Project Overview**

I have worked on analyzing a dataset of over 20,000 sales records from an Amazon-like e-commerce platform. This project involves extensive querying of customer behavior, product performance, and sales trends using Sql Server. Through this project, I have tackled various SQL problems, including revenue analysis, customer segmentation, and inventory management.

The project also focuses on data cleaning, handling null values, and solving real-world business problems using structured queries.

An ERD diagram is included to visually represent the database schema and relationships between tables.

---  
![Amazon ERD](Amazon%20ERD.png)
## **Database Setup & Design**

### **Schema Structure**

```-- category table
create table category
(
category_id  int primary key,
category_name varchar(20)
);

select * from category;
insert into category 
            select * from category_backup;

-- customers table
create table customers
(
customer_id int primary key,  
first_name  varchar(20),
last_name  varchar(20),
state varchar(20)
);

select * from customers;

insert into customers 
            select * from customers_backup;


-- sellers table
create table sellers
(
seller_id int primary key,
seller_name  varchar(25),
origin varchar(15)
);

select * from sellers;

insert into sellers 
            select * from sellers_backup;

-- products table
create table products
(
product_id int primary key,  
product_name varchar(50),  
price  float,
cogs  float,
category_id int, -- fk 
constraint product_fk_category foreign key(category_id) references category(category_id)
);

select * from products;

insert into products 
            select * from products_backup;


-- orders table
create table orders
(
order_id int primary key,   
order_date  date,
customer_id  int, -- fk
seller_id int, -- fk 
order_status varchar(15),
constraint orders_fk_customers foreign key (customer_id) references customers(customer_id),
constraint orders_fk_sellers foreign key (seller_id) references sellers(seller_id)
);

select * from orders;

insert into orders 
            select * from orders_backup;

-- order_items table
create table order_items
(
order_item_id int primary key,
order_id int,  -- fk 
product_id int, -- fk
quantity int,  
price_per_unit float,
constraint order_items_fk_orders foreign key (order_id) references orders(order_id),
constraint order_items_fk_products foreign key (product_id) references products(product_id)
);

select * from order_items;

insert into order_items 
            select * from order_items_backup;


-- payment table
create table payments
(
payment_id  
int primary key,
order_id int, -- fk   
payment_date date,
payment_status varchar(20),
constraint payments_fk_orders foreign key (order_id) references orders(order_id)
);

select * from payments;

insert into payments 
            select * from payments_backup;

--shippings table
create table shippings
(
shipping_id  int primary key,
order_id  int, -- fk
shipping_date date,  
return_date   date ,
shipping_providers  varchar(15),
delivery_status varchar(15),
constraint shippings_fk_orders foreign key (order_id) references orders(order_id)
);

select * from shippings where return_date is not null;

insert into shippings 
            select * from shipping_backup;

--inventory table
create table inventory
(
inventory_id int primary key,
product_id int, -- fk
stock int,
warehouse_id int,
last_stock_date date,
constraint inventory_fk_products foreign key (product_id) references products(product_id)
);
```


## **Objective**

The primary objective of this project is to showcase SQL proficiency through complex queries that address real-world e-commerce business challenges. The analysis covers various aspects of e-commerce operations, including:
- Customer behavior
- Sales trends
- Inventory management
- Payment and shipping analysis
- Forecasting and product performance
  

## **Identifying Business Problems**

Key business problems identified:
1. Low product availability due to inconsistent restocking.
2. High return rates for specific product categories.
3. Significant delays in shipments and inconsistencies in delivery times.
4. High customer acquisition costs with a low customer retention rate.

---

## **Solving Business Problems**

### Solutions Implemented:
```
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total orders, and total sales value.

-- join order_item -- order -- product
-- group by product id
-- total sale
-- top 10

select * from order_items;

--create a new column

alter table order_items
add  total_sale Float;

--Update table 
update order_items
set total_sale = quantity * price_per_unit;

select * from order_items
order by quantity desc;

select top 10
oi.product_id,p.product_name,
sum(oi.total_sale) as total_sale,
count(o.order_id) as total_orders
from orders as o
join order_items as oi
on o.order_id = oi.order_id
join products as p
on p.product_id=oi.product_id
group by oi.product_id,p.product_name
order by total_sale desc
```
----------------------------
```
2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.

-- category_id, category_name, total Sales, total cotribution 
-- oi -- products -- category
-- group by cate id, name


select p.category_id,
c.category_name,
sum(oi.total_sale) as total_sale,
sum(oi.total_sale)/(select sum(total_sale) from order_items) * 100 as contribution
from order_items as oi
join products as p
on p.product_id=oi.product_id
left join category c
on c.category_id = p.category_id
group by p.category_id,c.category_name
order by total_sale desc
```
-------------------------------------------------
```
3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.

--customer id join orders
--orders id join order items 
--average order value
--group cus id,name
--count order and count(order)>5

select c.customer_id,
Concat(c.first_name,' ',c.last_name) as full_name,
sum(total_sale)/count(o.order_id) as average_order_value,
count(o.order_id) as total_order
from orders o
join customers c 
on o.customer_id = c.customer_id
join order_items oi
on  o.order_id = oi.order_id
group by c.customer_id,c.first_name,c.last_name
Having count(o.order_id)>5;
```
------------------------------------------------
```
4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!

-- last 1 year data 
-- each month -- their sales and their previous month sale
-- window lag
select 
month,
year,
total_sales as current_month_sale,
lag(total_sales, 1) over(order by year,month) as last_month_sale
from
(
select 
datepart(month, o.order_date) as month,
datepart(year, o.order_date) as year,
round(sum(oi.total_sale),2) as total_sales
from orders as o
join order_items as oi
on oi.order_id = o.order_id
where o.order_date >= dateadd(year, -2, getdate()) --- date filtering
group by datepart(year, o.order_date), datepart(month, o.order_date)
) t1
order by year, month
```
```
5. Customers with No Purchases
Find customers who have registered but never placed an order.

-- approach 1
select *
from customers
where customer_id not in 
(select distinct customer_id from orders);

-- approach 2
select * from customers as c
left join
orders as o
on o.customer_id = c.customer_id
where o.customer_id is null
```
```
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.
---highest sales by cate with states

with ranking_table
as
(
select c.state ,cat.category_name,
sum(oi.total_sale) as total_sales,
Rank() over(partition by c.state 
order by sum(oi.total_sale) asc) as rank
from orders o join customers c on c.customer_id=o.customer_id 
join order_items oi on o.order_id=oi.order_id
join products p on p.product_id=oi.product_id
join category cat on cat.category_id=p.category_id
group by c.state,cat.category_name)
select * from ranking_table where rank = 1
order by state,total_sales asc;
```

```
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.


-- custpmer - order - oi
-- cus tomer id group by sum(total_sale) as cltv
-- order by total sale 
-- rank 

select c.customer_id,
Concat(c.first_name,' ',c.last_name) as full_name,
sum(total_sale) as Cltv,
dense_rank() over(order by sum(total_sale) Desc) as customer_ranking
from orders o
join customers c 
on o.customer_id = c.customer_id
join order_items oi
on  o.order_id = oi.order_id
group by c.customer_id,c.first_name,c.last_name
--order by cltv desc     ---highest puchased by  cust
```

```
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last re-stock date and warehouse information.

--curr stock left--
--last date stock--

select inv.inventory_id,p.product_name,
inv.stock as current_stock_left,
inv.last_stock_date,inv.warehouse_id
from inventory as inv
join products as p
on p.product_id = inv.product_id
where stock < 10;
```
```
9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.


--customer --o-- ship
--find difference shippings date and order date

select c.*,o.*,s.shipping_providers,
datediff(day, o.order_date, s.shipping_date) AS shipping_delay
from orders o join customers c
on o.customer_id = c.customer_id
join shippings s
on o.order_id = s.order_id 
where datediff(day, o.order_date, s.shipping_date) > 3
```

```
10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).

select pa.payment_status,
count(*) as total_count,
cast(count(*) as decimal(10,2))/
(select count(*) from payments) * 100 as percentage_p
from orders as o join payments as pa 
on o.order_id = pa.order_id
group by payment_status
```
```
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and 
failed orders, and display their percentage of successful orders.

with top_sellers as (
    select top 5
        s.seller_id,
        s.seller_name,
        sum(oi.total_sale) as total_sale
    from orders as o
    join sellers as s on o.seller_id = s.seller_id
    join order_items as oi on oi.order_id = o.order_id
    group by s.seller_id, s.seller_name
    order by total_sale desc
),
sellers_reports as (
    select 
        o.seller_id,
        ts.seller_name,
        o.order_status,
        count(*) as total_orders
    from orders as o
    join top_sellers as ts on ts.seller_id = o.seller_id
    where o.order_status not in ('inprogress', 'returned')
    group by o.seller_id, ts.seller_name, o.order_status
)
select ------total order then how much complete or cancel-----
    seller_id,
    seller_name,
    sum(case when order_status = 'completed' then total_orders else 0 end) as completed_orders,
    sum(case when order_status = 'cancelled' then total_orders else 0 end) as cancelled_orders,
    sum(total_orders) as total_orders,
    cast(
        sum(case when order_status = 'completed' then total_orders else 0 end) 
        * 100.0 / nullif(sum(total_orders), 0) 
        as decimal(10,2)
    ) as successful_orders_percentage
from sellers_reports
group by seller_id, seller_name;
-----------------------------------------------------------------------------------------------------
```
```
12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.

-- o - oi - prod
-- group pid sum(total_sale - cogs * qty) as profit

select p.product_id,p.product_name,
sum(total_sale - (p.cogs * oi.quantity)) as profit,
sum(total_sale - (p.cogs * oi.quantity))/sum(total_sale) * 100 as profit_margin,
dense_rank() over(order by 
sum(total_sale - (p.cogs * oi.quantity))/sum(total_sale) * 100 Desc) as profit_rank
from order_items oi
join products as p on oi.product_id = p.product_id
group by p.product_id,p.product_name
```
```
13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.

--oi--o

select p.product_id,p.product_name,
count(*) as total_unit_sold,
sum(case when o.order_status = 'Returned' then 1 else 0 end) 
as total_returned,
sum(case when o.order_status = 'Returned' then 1 else 0 end)/
cast(count(*) as decimal(10,2)) * 100 as return_percentage
from order_items as oi
join products as p
on oi.product_id = p.product_id
join orders as o on o.order_id = oi.order_id
group by p.product_id,p.product_name
order by return_percentage desc
```
```
14. Inactive Sellers
Identify sellers who haven’t made any sales in the last 12 months.
Challenge: Show the last sale date and total sales from those sellers.

 with ctel as ( --as these sellers has not done any sale in last 12 month
 select * from sellers 
 where seller_id not in (select seller_id from orders where 
 order_date >= dateadd(year, -1,getdate()))
 )select o.seller_id,
 max(o.order_date) as latest_date,
 max(total_sale) as last_sale_amount
 from orders o join ctel on
 ctel.seller_id=o.seller_id
 join order_items oi on 
 o.order_id = o.order_id
 group by o.seller_id
```
```
15. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns

select 
c_full_name as customers,
total_order,
total_returns,
case when total_returns > 5 then 'Returning_customers' else 'New'
end as customer_category
from 
(
select 
Concat(c.first_name,' ',c.last_name) as c_full_name,
count(o.order_id) as total_order,
sum(case when o.order_status = 'Returned' then 1 else 0 end) 
as total_returns
from orders as o
join customers as c
on c.customer_id = o.customer_id
join order_items as oi
on oi.order_id = o.order_id
group by c.first_name,c.last_name
) t1
 ``` 
```
16. Top 5 Customers by Orders in Each State
Identify the top 5 customers with
the highest number of orders for each state.
Challenge: Include the number of orders and
total sales for each customer.
--o--c--oi--

select * from 
(select c.state,
concat(c.first_name, ' ', c.last_name) as customers,
count(o.order_id) as total_orders,
sum(total_sale) as total_sale,
dense_rank() over(partition by c.state order by
count(o.order_id) desc) as rank
from orders as o
join order_items as oi
on oi.order_id = o.order_id
join customers as c
on c.customer_id = o.customer_id
group by c.state,c.first_name,c.last_name
) as t1 
where rank <=5
```
```
17. Calculate the total revenue(total sales) handled by each shipping provider.
Challenge: Include the total number of orders handled and 
the average delivery time for each provider.

--oi--o--shipping(gp by)
-- group by shipping provider id sum(total sale), total orders 

select 
s.shipping_providers,
count(o.order_id)as order_handled,
sum(oi.total_sale) as total_sale,
coalesce(avg(datediff(day,s.shipping_date,s.return_date)),0) as average_days
from orders as o
join order_items as oi
on oi.order_id = o.order_id
join shippings as s
on s.order_id = o.order_id
group by s.shipping_providers
```

```
19. Top 10 product with highest decreasing revenue ratio 
compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 
2023 revenue decrease ratio at end Round the result
Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)

-- join o -oi- p 
-- filter 2022
-- group by p id sum(total sale) 


-- join o -oi- p 
-- filter 2023
-- group by p id sum(total sale) 

-- join 1 -2 
with cte_2022 as
(
select p.product_id,p.product_name,
sum(oi.total_sale) as revenue
from orders as o
join order_items as oi
on oi.order_id = o.order_id
join products as p
on p.product_id = oi.product_id
where datepart(year,o.order_date) = 2022
group by p.product_id,p.product_name
),
cte_2023 as
(
select p.product_id,p.product_name,
sum(oi.total_sale) as revenue
from orders as o
join order_items as oi
on oi.order_id = o.order_id
join products as p
on p.product_id = oi.product_id
where datepart(year,o.order_date) = 2023
group by p.product_id,p.product_name
) 
select top 5 cs.product_id,
	ls.revenue as last_year_revenue,
	cs.revenue as current_year_revenue,
	ls.revenue - cs.revenue as rev_diff,
	ROUND((cs.revenue - ls.revenue)/cast(ls.revenue as decimal(10,2))* 100,2) as reveneue_dec_ratio
from cte_2022 as ls 
join cte_2023 as cs
on ls.product_id=cs.product_id
where ls.revenue > cs.revenue
order by reveneue_dec_ratio desc;
```
-- Store PROCEDURE

```
Final Task
-- Store Procedure
create a function as soon as the product is sold the the same quantity should reduced from inventory table
after adding any sales records it should update the stock in the inventory table based on the product and qty purchased
-- 


select * from products
--prod_id 1 ---Apple AirPods 3rd Gen --inv--55
--prod_id 2 ---Apple AirPods Max     --inv--39

select * from inventory;

select * from orders;
select * from order_items;


create or alter procedure add_sales
    @p_order_id int,
    @p_customer_id int,
    @p_seller_id int,
    @p_order_item_id int,
    @p_product_id int,
    @p_quantity int
as
begin
    declare @v_count int;
    declare @v_price float;
    declare @v_product varchar(50);

    -- check if the order_id already exists to prevent duplicate entry
    if exists (select 1 from orders where order_id = @p_order_id)
    begin
        print '⚠️ order already exists! use a different order_id.';
        return;
    end

    -- fetching product name and price based on product_id entered
    select @v_price = price, @v_product = product_name
    from products
    where product_id = @p_product_id;

    -- checking stock and product availability in inventory
    select @v_count = count(*)
    from inventory
    where product_id = @p_product_id
      and stock >= @p_quantity;

    if @v_count > 0
    begin
        -- insert into orders table
        insert into orders (order_id, order_date, customer_id, seller_id)
        values (@p_order_id, getdate(), @p_customer_id, @p_seller_id);

        -- insert into order_items table
        insert into order_items (order_item_id, order_id, product_id, quantity, price_per_unit, total_sale)
        values (@p_order_item_id, @p_order_id, @p_product_id, @p_quantity, @v_price, @v_price * @p_quantity);

        -- update inventory stock
        update inventory
        set stock = stock - @p_quantity
        where product_id = @p_product_id;

        print '✅ sale added successfully! product: ' + @v_product + ' stock updated.';
    end
    else
    begin
        print '⚠️ insufficient stock for product: ' + @v_product;
    end
end;

exec add_sales 
    @p_order_id = 25005,
    @p_customer_id = 2, 
    @p_seller_id = 5, 
    @p_order_item_id = 25004,
    @p_product_id = 1, 
    @p_quantity = 14;
exec sp_columns orders;

--✅ sale added successfully! product: airpods 3rd gen stock updated.
--⚠️ order already exists! use a different order_id.
--⚠️ insufficient stock for product: airpods 3rd gen.
```
---

---

## **Learning Outcomes**

This project enabled me to:
- Design and implement a normalized database schema.
- Clean and preprocess real-world datasets for analysis.
- Use advanced SQL techniques, including window functions, subqueries, and joins.
- Conduct in-depth business analysis using SQL.
- Optimize query performance and handle large datasets efficiently.

---

## **Conclusion**

This advanced SQL project successfully demonstrates my ability to solve real-world e-commerce problems using structured queries. From improving customer retention to optimizing inventory and logistics, the project provides valuable insights into operational challenges and solutions.

By completing this project, I have gained a deeper understanding of how SQL can be used to tackle complex data problems and drive business decision-making.
