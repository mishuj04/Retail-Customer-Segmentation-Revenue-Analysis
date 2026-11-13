CREATE TABLE raw_retail (invoice VARCHAR(50), stock_code VARCHAR(50), description TEXT, quantity INT, invoice_date TIMESTAMP, price NUMERIC(10,2), customer_id INT, country VARCHAR(50));

ALTER TABLE raw_retail ALTER COLUMN customer_id TYPE NUMERIC

select * from raw_retail

select count(*) from raw_retail

-- customer_id not null
select count(*) from raw_retail where customer_id is not null

-- customer_id not null and not cancelled
select count(*) from raw_retail where customer_id is not null and invoice not like 'C%'

CREATE VIEW sales_clean AS
SELECT DISTINCT invoice, stock_code, description, quantity, invoice_date,
       price, customer_id::INT AS customer_id, country,
       quantity * price AS revenue
FROM raw_retail
WHERE customer_id IS NOT NULL AND invoice NOT LIKE 'C%'
  AND quantity > 0 AND price > 0 AND stock_code ~ '^[0-9]{5}';

-- return analysis
with sold as (select stock_code, sum(quantity) as units_sold from raw_retail where customer_id is not null and invoice not like 'C%' and quantity>0 group by 1), return as (select stock_code, sum(quantity) as units_return from raw_retail where customer_id is not null and invoice like 'C%' group by 1) select s.stock_code, s.units_sold, r.units_return, round(100* units_return/units_sold, 2) as return_rate_pct from units_sold s join units_return r on s.stock_code=r.stock_code where s.units_sold>500 order by return_rate_pct desc;

-- Wholesale vs retail
with per_cust as (select customer_id, sum(quantity)::numeric/count(distinct invoice) as units_per_order, sum(revenue) as revenue, count(distinct invoice) as orders from sales_clean group by 1) select case when units_per_order >= 150 then 'Wholesale-type' else 'Retail-type' end as cust_type, count(*) as customers, round(avg(orders),1) as avg_orders, round(sum(revenue)) as revenue from per_cust group by 1
