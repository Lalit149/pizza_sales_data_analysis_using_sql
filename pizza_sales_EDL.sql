
SELECT * FROM order_details;
SELECT * FROM orders;
SELECT * FROM pizza_types;
SELECT * FROM pizzas;

-- 1. Retrieve the total number of orders placed.
SELECT 
    COUNT(order_details_id)
FROM
    order_details;



-- 2. Calculate the total revenue generated from pizza sales.

SELECT 
	ROUND(SUM(o.quantity*p.price),4) AS 'TOTAL REVENUE'
FROM order_details o
join pizzas p
	ON o.pizza_id = p.pizza_id;



-- 3. Identify the highest-priced pizza.

SELECT 
    p2.name, p1.price
FROM
    pizzas p1
        JOIN
    pizza_types p2 ON p1.pizza_type_id = p2.pizza_type_id
ORDER BY price DESC
LIMIT 1;


-- 4.Identify the 5 most common pizza size ordered.

SELECT 
    *
FROM
    (SELECT 
        TRIM(o.pizza_id) AS pizza_size_id,
            COUNT(TRIM(p.size)) AS `count`
    FROM
        order_details o
    JOIN pizzas p ON o.pizza_id = p.pizza_id
    GROUP BY pizza_size_id) AS sub1
ORDER BY `count` DESC
LIMIT 5;



-- 5. List the top 5 most ordered pizza types along with their quantities.

SELECT 
    p1.name AS `name`, SUM(o.quantity) AS quantity
FROM
    order_details o
        JOIN
    pizzas p ON o.pizza_id = p.pizza_id
        JOIN
    pizza_types p1 ON p.pizza_type_id = p1.pizza_type_id
GROUP BY `name`
ORDER BY quantity DESC
LIMIT 5;


-- 6. Determine the distribution of orders by hour of the day.

SELECT * 
FROM orders;
ALTER TABLE orders
MODIFY COLUMN `date` DATE,
MODIFY COLUMN `time` TIME;

WITH cte_time AS(
SELECT 
	o.`time`,
    od.order_id
FROM order_details od
JOIN orders o
ON od.order_id = o.order_id)
SELECT
	HOUR(time) As hour,
	count(DISTINCT(order_id)) as count_
FROM cte_time
GROUP BY hour
;
-- OR -------------
SELECT 
    HOUR(time) AS hour, COUNT(order_id)
FROM
    orders
GROUP BY hour; 



-- 7. Join relevant tables to find the category-wise distribution of pizzas.

SELECT 
    category, COUNT(o.order_details_id) AS total
FROM
    order_details o
        JOIN
    pizzas p ON o.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY category;



-- 8.Group the orders by date and calculate the average number of pizzas ordered per day.
select count(distinct(order_id)) from order_details;
WITH cte_avg as(
SELECT 
	date(o.date) as `date`,
    count(od.order_details_id) as total_pizzas_ordered
FROM order_details od
JOIN orders o
	on od.order_id = o.order_id
GROUP BY `date`
ORDER BY `date`)
SELECT
	`date`,
    total_pizzas_ordered,
    MONTHNAME(date) as `month`,
    QUARTER(date) as `quarter`,
    ROUND(AVG(total_pizzas_ordered) over(),2) as total_average,
    ROUND(AVG(total_pizzas_ordered) OVER(PARTITION BY QUARTER(date)),2) as quarterly_average,
    ROUND(AVG(total_pizzas_ordered) OVER(PARTITION BY MONTH(date)),2) as monthly_average
FROM cte_avg;


-- 9.Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    TRIM(pt.name) AS `NAME`, ROUND(SUM(o.quantity * p.price), 2) as revenue
FROM
    order_details o
        JOIN
    pizzas p ON o.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY `NAME`
ORDER BY revenue DESC
LIMIT 3;

    

-- 10. Calculate the percentage contribution of each pizza type to total revenue.

SELECT 
	name,
    CONCAT(ROUND(pizza_sum/total_sum*100,2),'%') AS percentage
FROM
(SELECT 
	*,
    SUM(pizza_sum) over() as total_sum
FROM 
(
SELECT 
	p2.name as name,
   sum(quantity*price) as pizza_sum
FROM pizzas p1
	JOIN
order_details o ON p1.pizza_id = o.pizza_id
	JOIN
pizza_types p2 ON p2.pizza_type_id = p1.pizza_type_id 
GROUP BY name) 
as sub1)as sub2;





-- 11. Analyze the cumulative revenue generated over time.
SELECT
	*,
    ROUND(SUM(revenue) over(order by date) ,2) as rev_over_time
FROM
(SELECT 
	date,
	ROUND(SUM(quantity*price),2) as revenue
FROM order_details od
JOIN pizzas p1
	on od.pizza_id = p1.pizza_id
JOIN orders o
	ON od.order_id = o.order_id
GROUP BY date) as sub1;


-- 12. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT
	category,
    name,
    revenue
FROM 
(SELECT 
	category,
    name,
    sum(quantity*price) as revenue,
    rank() over(partition by category order by sum(quantity*price) desc) as ranking
FROM order_details od
join orders o 
	on od.order_id = o.order_id
join pizzas p
	on p.pizza_id = od.pizza_id
join pizza_types pt
	on pt.pizza_type_id = p.pizza_type_id
GROUP BY category,name
ORDER BY category) AS sub1
WHERE ranking<=3
;
