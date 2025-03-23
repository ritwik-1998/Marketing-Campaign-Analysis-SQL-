CREATE DATABASE retail_campaign

USE retail_campaign

SELECT * FROM dim_campaigns
SELECT * FROM dim_products
SELECT * FROM dim_stores
SELECT * FROM fact_events

----Check For Duplicate values----

SELECT COUNT(*) FROM fact_events;
SELECT COUNT(DISTINCT event_id) FROM fact_events;

------Removing Null Values--------

SELECT * FROM fact_events
WHERE 
    event_id IS NULL 
	OR 
	store_id IS NULL
	OR 
	campaign_id IS NULL 
	OR 
    product_code IS NULL
	OR 
	base_price IS NULL
	OR 
	promo_type IS NULL 
	OR 
    quantity_sold_before_promo IS NULL 
	OR 
	quantity_sold_after_promo IS NULL;

DELETE FROM fact_events
WHERE 
    event_id IS NULL 
	OR 
	store_id IS NULL
	OR 
	campaign_id IS NULL 
	OR 
    product_code IS NULL
	OR 
	base_price IS NULL
	OR 
	promo_type IS NULL 
	OR 
    quantity_sold_before_promo IS NULL 
	OR 
	quantity_sold_after_promo IS NULL;



----------------------------------------Business Requests-------------------------------------------------

---Request 1) Provide a list of products with a base price greater than 500 and that are featured in promo type of 
-------------'BOGOF' (Buy One Get One Free). This information will help us identify high-value products that are currently being 
--- ----------heavily discounted, which can be useful for evaluating our pricing and promotion strategies.---------------


WITH cte1 AS(
     SELECT a.product_name, b.product_code, b.promo_type, b.base_price
     FROM dim_products a
     INNER JOIN fact_events b
     ON a.product_code=b.product_code
     WHERE base_price>500)
SELECT DISTINCT product_name, product_code, promo_type, base_price
FROM cte1
WHERE promo_type='BOGOF';

---REQUEST 2) Generate a report that provides an overview of the number of stores in each city.
----------The results will be sorted in descending order of store counts, allowing us to identify the cities with the 
----------highest store presence. The report includes two essential fields: city and store count,
----------which will assist in optimizing our retail operations.--------


SELECT city, count(store_id) AS store_count
FROM dim_stores
GROUP BY city;

-------REQUEST 3) Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
--------------    The report includes three key fields:
--------------         a)campaign_name
--------------         B)total_revenue(before_promotion)
--------------         C)total_revenue(after_promotion)
--------------    This report should help in evaluating the financial impact of our promotional campaigns. (Display the values in millions)


with cte2 as(
      SELECT *, 
        (base_price*quantity_sold_before_promo) as RBP, 
         (case
		     WHEN promo_type= 'BOGOF' then (0.5*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '50% OFF' then (0.5*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '25% OFF' then (0.75*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '33% OFF' then (0.67*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '500 Cashback' then (((base_price-500)*quantity_sold_after_promo))END)
			 as RAP    
        from fact_events)
select a.campaign_name, sum(b.RBP) as TRBP, sum(b.RAP) as TRAP
from dim_campaigns a
inner join cte2 b
on a.campaign_id=b.campaign_id
group by campaign_name;



--------Request 4) Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign.
--------          Additionally, provide rankings for the categories based on their ISU%. The report will include three key fields:
---------         a)category
---------         b)isu%
---------         c)rank order
---------         This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales.

with cte3 as(
        SELECT a.category, sum(b.quantity_sold_before_promo) as QSBP, sum(b.quantity_sold_after_promo) as QSAP
        from dim_products a
        inner join fact_events b
        on a.product_code=b.product_code
        where b.campaign_id = 'CAMP_DIW_01'
		group by category
		)
Select * , ROUND((QSAP - QSBP) / (QSBP), 2)*100 as ISU
from cte3 ORDER BY ISU DESC


------------CITY WISE TOTAL REVENUE AFTER PROMOTION-----

with cte2 as(
      SELECT *, 
        (base_price*quantity_sold_before_promo) as RBP, 
         (case
		     WHEN promo_type= 'BOGOF' then (0.5*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '50% OFF' then (0.5*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '25% OFF' then (0.75*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '33% OFF' then (0.67*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '500 Cashback' then (((base_price-500)*quantity_sold_after_promo))END)
			 as RAP    
        from fact_events)
Select a.city, sum(b.RAP) as TRAP  
from dim_stores a
inner join cte2 b
on a.store_id= b.store_id
group by city order by TRAP desc;

-----------CALCULATE THE CAMPAIGN WISE TOTAL REVENUE. IT WILL GIVE A OVER ALL IDEA ABOUT WHICH CAMPAIGN PERFORMED BETTER.-------


with cte2 as(
      SELECT *, 
        (base_price*quantity_sold_before_promo) as RBP, 
         (case
		     WHEN promo_type= 'BOGOF' then (0.5*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '50% OFF' then (0.5*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '25% OFF' then (0.75*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '33% OFF' then (0.67*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '500 Cashback' then (((base_price-500)*quantity_sold_after_promo))END)
			 as RAP    
        from fact_events)
SELECT B.Campaign_Name, SUM(a.RAP) AS TRAP, SUM(a.RBP) AS TRBP
FROM dim_campaigns B
INNER JOIN cte2 A
ON B.campaign_id=A.campaign_id
GROUP BY campaign_name ORDER BY TRAP DESC


---------Ranking of the cities according to the Revenue performance after promotion-----


with cte2 as(
      SELECT *, 
        (base_price*quantity_sold_before_promo) as RBP, 
         (case
		     WHEN promo_type= 'BOGOF' then (0.5*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '50% OFF' then (0.5*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '25% OFF' then (0.75*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '33% OFF' then (0.67*base_price*quantity_sold_after_promo)
			 WHEN promo_type= '500 Cashback' then (((base_price-500)*quantity_sold_after_promo))END)
			 as RAP    
        from fact_events)
select a.city, sum(b.RAP) as Total_Revenue_after_promo,
RANK()over(order by Sum(b.rap) desc) as City_rank
from dim_stores a
inner join cte2 b
on a.store_id= b.store_id
group by city

