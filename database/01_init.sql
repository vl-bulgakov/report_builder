CREATE OR REPLACE FUNCTION  fn_create_tables()
RETURNS void AS $$

begin

CREATE TABLE IF NOT EXISTS public.claims_sample_data (
    "MONTH" int8,
    SERVICE_CATEGORY varchar(50),
    CLAIM_SPECIALTY varchar(50),
    PAYER varchar(50),
    PAID_AMOUNT int8
);


DROP MATERIALIZED VIEW IF EXISTS mv_agg_amounts_dds, mv_agg_forecast;


CREATE MATERIALIZED VIEW mv_agg_amounts_dds as
select 
case when t_date is not null and service_category is not null and payer is not null then 't_date, service_category, payer'
	when t_date is not null and service_category is not null and payer is null then 't_date, service_category'
	when t_date is not null and service_category is null and payer is not null then 't_date, payer'
	when t_date is null and service_category is not null and payer is not null then 'service_category, payer'
	when t_date is not null and service_category is null and payer is null then 't_date'
	when t_date is null and service_category is not null and payer is null then 'service_category'
	when t_date is null and service_category is null and payer is not null then 'payer'
	else null end agg_level
,case when t_date is null then '0' else t_date::text end t_date 
,case when service_category is null then '0' else service_category end service_category 
,case when payer is null then '0' else payer end payer 
,sum_paid_amount
,categories
,avg_category_receipt
,plus_paid_amount
,minus_paid_amount
,empty_claim_specialty
from(
	select
	TO_DATE(CAST("MONTH"  AS VARCHAR), 'YYYYMM') as t_date
	, service_category
	, payer
	, sum (paid_amount) sum_paid_amount
	, count(paid_amount) categories
	, sum (paid_amount)/count(paid_amount) avg_category_receipt
	, sum(case when paid_amount>0 then 1 else 0 end) plus_paid_amount
	, sum(case when paid_amount<0 then 1 else 0 end) minus_paid_amount
	, sum(case when claim_specialty = '' or claim_specialty is null then 1 else 0 end)empty_claim_specialty
	from claims_sample_data csd
	GROUP BY GROUPING SETS ((t_date, service_category, payer)
							, (t_date, service_category)
							, (t_date, payer)
							, (payer, service_category)
							, (t_date)
							, (service_category)
							, (payer))
	) tmp
order by agg_level,  t_date desc, service_category, payer ;


drop table if exists raw_data_table;

create table raw_data_table as
select
TO_DATE(CAST("MONTH"  AS VARCHAR), 'YYYYMM') as t_date
,service_category
,payer
,sum(paid_amount) sum_paid_amount
from claims_sample_data csd
group by t_date
,service_category
,payer;



CREATE MATERIALIZED VIEW mv_agg_forecast as
select 
agg_level
,forecast_date
,service_category
,payer
,sum_paid_amount
,rolling_avg::int rolling_avg
,seasonal_avg::int seasonal_avg
,exponential_avg::int exponential_avg
,seasonal_exponential_avg::int seasonal_exponential_avg
from(
select
	't_date, service_category, payer' as agg_level,
    t_date + INTERVAL '6 MONTH' AS forecast_date,
    service_category,
    payer,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category, payer
        ORDER BY t_date
        ROWS BETWEEN 6 following  AND 6 following 
    ) AS sum_paid_amount,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category, payer
        ORDER BY t_date
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    ) AS rolling_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category, payer, EXTRACT(MONTH FROM t_date)
        ORDER BY EXTRACT(YEAR FROM t_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS seasonal_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category, payer
        ORDER BY t_date 
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    ) * EXP(-0.1) AS exponential_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category, payer, EXTRACT(MONTH FROM t_date)
        ORDER BY EXTRACT(YEAR FROM t_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 preceding
        )* EXP(-0.1) AS seasonal_exponential_avg
FROM raw_data_table
where t_date < '2020-06-01'
order by forecast_date desc,
    service_category,
    payer
   )tmp
union all 
select 
agg_level
,forecast_date
,service_category
,payer
,sum_paid_amount
,rolling_avg::int rolling_avg
,seasonal_avg::int seasonal_avg
,exponential_avg::int exponential_avg
,seasonal_exponential_avg::int seasonal_exponential_avg
from(
select
	't_date, service_category' as agg_level,
    t_date + INTERVAL '6 MONTH' AS forecast_date,
    service_category,
    '0' as payer,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category
        ORDER BY t_date
        ROWS BETWEEN 6 following  AND 6 following 
    ) AS sum_paid_amount,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category
        ORDER BY t_date
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    ) AS rolling_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category,  EXTRACT(MONTH FROM t_date)
        ORDER BY EXTRACT(YEAR FROM t_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS seasonal_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category
        ORDER BY t_date 
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    ) * EXP(-0.1) AS exponential_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY service_category,  EXTRACT(MONTH FROM t_date)
        ORDER BY EXTRACT(YEAR FROM t_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 preceding
        )* EXP(-0.1) AS seasonal_exponential_avg
FROM (select t_date,
    service_category, sum (sum_paid_amount) sum_paid_amount  from raw_data_table group by t_date, service_category) t
where t_date < '2020-06-01'
order by forecast_date desc,
    service_category,
    payer
   )tmp
union all 
select 
agg_level
,forecast_date
,service_category
,payer
,sum_paid_amount
,rolling_avg::int rolling_avg
,seasonal_avg::int seasonal_avg
,exponential_avg::int exponential_avg
,seasonal_exponential_avg::int seasonal_exponential_avg
from(
select
	't_date, payer' as agg_level,
    t_date + INTERVAL '6 MONTH' AS forecast_date,
    '0' as service_category,
    payer,
    AVG(sum_paid_amount) OVER (
        PARTITION BY payer
        ORDER BY t_date
        ROWS BETWEEN 6 following  AND 6 following 
    ) AS sum_paid_amount,
    AVG(sum_paid_amount) OVER (
        PARTITION BY payer
        ORDER BY t_date
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    ) AS rolling_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY payer, EXTRACT(MONTH FROM t_date)
        ORDER BY EXTRACT(YEAR FROM t_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS seasonal_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY payer
        ORDER BY t_date 
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    ) * EXP(-0.1) AS exponential_avg,
    AVG(sum_paid_amount) OVER (
        PARTITION BY payer, EXTRACT(MONTH FROM t_date)
        ORDER BY EXTRACT(YEAR FROM t_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 preceding
        )* EXP(-0.1) AS seasonal_exponential_avg
FROM (select t_date, payer, sum (sum_paid_amount) sum_paid_amount  from raw_data_table group by t_date, payer) t
where t_date < '2020-06-01'
order by forecast_date desc,
    service_category,
    payer
   )tmp
union all 
select 
agg_level
,forecast_date
,service_category
,payer
,sum_paid_amount
,rolling_avg::int rolling_avg
,seasonal_avg::int seasonal_avg
,exponential_avg::int exponential_avg
,seasonal_exponential_avg::int seasonal_exponential_avg
from(
select
	't_date' as agg_level,
    t_date + INTERVAL '6 MONTH' AS forecast_date,
    '0' as service_category,
    '0' as payer,
    AVG(sum_paid_amount) OVER (
        ORDER BY t_date
        ROWS BETWEEN 6 following  AND 6 following 
    ) AS sum_paid_amount,
    AVG(sum_paid_amount) OVER (
        ORDER BY t_date
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    ) AS rolling_avg,
    AVG(sum_paid_amount) OVER (
        ORDER BY EXTRACT(YEAR FROM t_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS seasonal_avg,
    AVG(sum_paid_amount) OVER (
        ORDER BY t_date 
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    ) * EXP(-0.1) AS exponential_avg,
    AVG(sum_paid_amount) OVER (
        ORDER BY EXTRACT(YEAR FROM t_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 preceding
        )* EXP(-0.1) AS seasonal_exponential_avg
FROM (select t_date, sum (sum_paid_amount) sum_paid_amount  from raw_data_table group by t_date) t
where t_date < '2020-06-01'
order by forecast_date desc,
    service_category,
    payer
   )tmp
order by agg_level,
	forecast_date desc,
    service_category,
    payer;


END;
$$ LANGUAGE plpgsql;

SELECT fn_create_tables();
