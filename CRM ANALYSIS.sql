/*For the Maven Sales Challenge, you'll play the role of a BI Developer for MavenTech, a company that 
specializes in selling computer hardware to large businesses. They've been using a new CRM system to 
track their sales opportunities but have no visibility of the data outside of the platform.
In an effort to become a data-driven organization, you've been asked to create an interactive dashboard 
that enables sales managers to track their team's quarterly performance.

WE ARE GOING TO LOOK AT THE FOLLOWING:
1. CLEANING OF DATA BY CHECKING FOR ANY NULL VALUES IN EACH TABLES AND ALSO ALL THE TABLE COMBINED, AND  REMOVE THEM IF PRESENT FOR BETTER REPRESENTATION.
2. EDA(EXPLORATORY DATA ANALYSIS TO LOOK INDEPT INTO EACH TABLE )


STRUCTURE OF THE TABLES: IT COMPRISES OF FOUR TABLES WITH INCLUDES-
SALES_TEAMS
SALES_PIPELINE
ACCOUNT
PRODUCT.

 NOTE; MYSQL WORKBENCH 8.0 WAS USE FOR THE BOVE STATEMENTS AND ALSO FOR OTHER MANIPULTIONS IN THE DATA 
 WHILE MICROSOFT POWER BI WS USED FOR THE VISUALISATIONS
*/
 
 
 -- FIRST LETS CHECK FOR NULL VALUE FOR EACH TABLES
 DELIMITER //
 CREATE PROCEDURE DATA_CLEANING()
 BEGIN
	SET SQL_SAFE_UPDATES=0;
    
SELECT * FROM project.sales_teams
	where sales_agent is null
	or manager is null
	or regional_office is null;-- SALES TEAM TABLE

SELECT * FROM project.sales_pipeline
	where opportunity_id is null
	or sales_agent is null
	or product is null
	or account is null
	or deal_stage is null
	or engage_date is null
	or close_date is null
	or close_value is null;-- SALES PIPELINE TABLE

SELECT * FROM project.accounts
	where account is null
	or sector is null
	or year_established is null
	or revenue is null
	or employees is null
	or office_location is null
	or subsidiary_of is null; -- ACCOUNTS TABLE
    
SELECT * FROM project.products
	where product is null
	or series is null
	or sales_price is null;-- PRODUCT TABLE
    
    -- CHECK FOR DUPLICATE IN EACH TABLE
    SELECT * FROM sales_teams
    group by sales_agent
    HAVING COUNT(*)>1;
    
	SELECT * FROM sales_pipeline
	group by opportunity_id
    HAVING COUNT(*)>1;
    
    SELECT * FROM accounts
	group by sector
    HAVING COUNT(*)>1;
    
    SELECT * FROM products
    group by product
    HAVING COUNT(*)>1;
    
SELECT P.*,S.manager,regional_office -- THIS JOIN IS NETWEEN SALES PIPELINE AND SALES TEAM
				FROM sales_pipeline P 
				RIGHT JOIN sales_teams S 
				ON P.sales_agent = S.sales_agent
                WHERE opportunity_id<>'';
                
WITH D AS (SELECT P.*,S.manager,regional_office 
				FROM sales_pipeline P 
				RIGHT JOIN sales_teams S 
				ON P.sales_agent = S.sales_agent
                WHERE opportunity_id<>'')
SELECT D.*,A.sector,year_established,revenue,employees,office_location-- THIS JOIN IS BETWEEN SALES PIPELINE,SALES TEAM AND ACCOUNTS
			FROM D 
			RIGHT JOIN accounts A 
			ON D.account = A.account;               
	
 -- WE NEED TO JOIN ALL THE TABLES TOGETHER USING THE COMMON COLUMNS AMONG THEM CHECK FOR NULL VALUES PRESENT 
WITH K AS (WITH D AS (SELECT P.*,S.manager,regional_office -- THIS JOIN IS NETWEEN SALES PIPELINE AND SALES TEAM
				FROM sales_pipeline P 
				RIGHT JOIN sales_teams S 
				ON P.sales_agent = S.sales_agent
                WHERE opportunity_id<>'')
			SELECT D.*,A.sector,year_established,revenue,employees,office_location-- THIS JOIN IS BETWEEN SALES PIPELINE,SALES TEAM AND ACCOUNTS
			FROM D 
			RIGHT JOIN accounts A 
			ON D.account = A.account)
	SELECT K.*,R.series,sales_price-- WHILE THIS JOIN CONSIST OF ALL THE TABLE 
	FROM K
	LEFT JOIN products R 
	ON K.product = R.product
    WHERE series<>'';-- AFTER CHECKING FOR THE VALUE, WE HAVE ABOUT 1,146 WHICH WAS SUBTRACTED FROM THE TOTAL OF 6711
END //
DELIMITER ;
CALL DATA_CLEANING();
 
 -- A VIEW WAS CREATED NAMED COMBINED DATA IN OTHER TO SIMPLIFY THE QUERY COMPLICATION AND ALSO FOR QUICK RESPONSE TIME 
CREATE VIEW COMBINED_DATA AS
WITH K AS (WITH D AS (SELECT P.*,S.manager,regional_office -- THIS JOIN IS NETWEEN SALES PIPELINE AND SALES TEAM
				FROM sales_pipeline P 
				RIGHT JOIN sales_teams S 
				ON P.sales_agent = S.sales_agent
                WHERE opportunity_id<>'')
			SELECT D.*,A.sector,year_established,revenue,employees,office_location-- THIS JOIN IS BETWEEN SALES PIPELINE,SALES TEAM AND ACCOUNTS
			FROM D 
			RIGHT JOIN accounts A 
			ON D.account = A.account)
	SELECT K.*,R.series,sales_price-- WHILE THIS JOIN CONSIST OF ALL THE TABLE 
	FROM K
	LEFT JOIN products R 
	ON K.product = R.product
    WHERE series<>'';



/* EDA(EXPLORATORY DATA ANALYSIS TO LOOK INDEPT INTO EACH TABLE) FOR
						PRODUCT ANALYSIS
 QST1: WHAT IS THE DISTRIBUTION OF PRODUCT BY SERIES */
 SELECT series, COUNT(series)Distribution from combined_data
group by series;

SELECT product, COUNT(product)Distribution from combined_data
group by product;


-- QST 2: WHAT IS THE DISTRIBUTION OF SALES PRICE FOR INDIVIDUAL PRODUCT 

SELECT product,concat('$','',sales_price)sales_price from combined_data
group by product; 

/* EDA(EXPLORATORY DATA ANALYSIS TO LOOK INDEPT INTO EACH TABLE) FOR
						SALES PIPELINE ANALYSIS
 QST1: WHAT IS THE TOTAL VALUE OF OPPORTUNITY IN THE SLES PIPELINE BY REGION
 */
SELECT distinct regional_office, count(opportunity_id)opportunities from combined_data
group by regional_office
order by opportunities desc;

-- QST 2: WHAT IS THE TOTAL VALUE OF OPPORTUNITY IN THE SALES PIPELINE BY DEAL_STAGE
SELECT distinct  deal_stage, count(deal_stage)status from combined_data
group by deal_stage;
 
SELECT distinct regional_office,deal_stage,
count(opportunity_id) over(partition by regional_office,deal_stage)status, 
COUNT(regional_office) over(partition by deal_stage) opportunity from combined_data
order by opportunity desc;
 
-- QST 3: WHAT IS THE DISTRIBUTION OF  OPPORTUNITY AND CLOSE DEAL ACROSS DEAL_STAGE
SELECT deal_stage,concat('$','',SUM(close_value))close_deal,
concat('$','',avg(close_value)over(partition by deal_stage))avg_deal,
COUNT(opportunity_id)opportunity_count  
from combined_data
group by deal_stage;

-- QST 4: WHAT IS THE DISTRIBUTION OF SALES_AGENT PERFORMANCE, MANAGER AND PRODUCT ACROSS DIFFERENT ACCOUNT OR SECTOR
WITH CTE1 AS (
select opportunity_id,regional_office,manager,sales_agent,product,sector,account,
count(deal_stage) over(partition by sales_agent)distribution, deal_stage
from combined_data
 where  deal_stage ='won'
order by distribution desc),
CTE2 AS (
select opportunity_id, regional_office,manager,sales_agent,product,sector,account,
count(deal_stage)over(partition by sales_agent)lost,deal_stage
from combined_data
where  deal_stage ='lost'
order by lost desc),
CTE3 AS(
select opportunity_id,regional_office,manager,sales_agent,product,sector,account,
count(deal_stage) over(partition by sales_agent)engaged,deal_stage
from combined_data
where  deal_stage ='engaging'
order by engaged desc),
CTE4 AS(
select opportunity_id,regional_office,manager,sales_agent,product,sector,account,
count(deal_stage) over(partition by sales_agent)prospecting,deal_stage
from combined_data
where  deal_stage ='prospecting'
order by prospecting desc)

select * FROM CTE1
UNION
select * FROM CTE2
UNION
select * FROM CTE3
UNION 
select * FROM CTE4;



							-- ACCOUNT ANALYSIS--
                            
-- QST 1: WHAT IS THE DISTRIBUTION OF ACCOUNT BY SECTOR
SELECT distinct sector,
count(sector) over(partition by sector ) distribution 
from combined_data
order by distribution desc;

-- >>>>>>>>>>>>>>
SELECT count(account)total_account from accounts;

-- QST 2: HOW DOES THE DISTRIBUTION OF ACCOUNT REVENUE VARY ACROSS DIFFERENT SECTOR
SELECT distinct sector,
floor(sum(revenue) over())total_revenue, 
floor(sum(revenue) over(partition by sector )) distribution 
from combined_data
order by distribution desc;

-- QST 3: WHAT IS THE TREND IN THE NUMBER OF ACCOUNT ESTABLISHED OVER THE YEARS
SELECT distinct count(account) over(partition by sector,year_established,office_location)accountt,sector,year_established, office_location 
from combined_data
order by sector asc;

-- QST 4 WHAT IS THE TREND IN THE NUMBERS OF EMPLOYEES OVER THE YEARS
SELECT distinct count(account) 
over(partition by sector,year_established,employees order by year_established asc)accountt,
sector,year_established,employees,office_location 
from combined_data
order by sector asc;


									-- SALES TEAM PERFORMANCE--
                                    
-- QST 1: WHAT IS THE DISTRIBUTION OF DEAL STAGE ACROSS SALES_AGENTS
WITH  CTE1 AS(
select distinct sales_agent, manager, count(deal_stage) over(partition by sales_agent,manager)Distribution,deal_stage 
from combined_data
where deal_stage = 'won'
order by Distribution desc),

CTE2 AS(
select distinct sales_agent,manager, 
count(deal_stage) over(partition by sales_agent,manager)lost, deal_stage
from combined_data
where deal_stage = 'lost'
order by lost desc),

CTE3 AS(
select distinct sales_agent, manager,
count(deal_stage) over(partition by sales_agent,manager)engaged, deal_stage 
from combined_data
where deal_stage = 'engaging'
order by engaged desc),

CTE4 AS(
select distinct sales_agent,manager, 
count(deal_stage) over(partition by sales_agent,manager)prospect,deal_stage 
from combined_data
where deal_stage = 'prospecting'
order by prospect desc)

select * FROM CTE1
UNION
select * FROM CTE2
UNION
select * FROM CTE3
UNION 
select * FROM CTE4;

-- QST 2: WHAT IS THE  DISTRIBUTION OF SALES AGENTS BY REGIONAL_OFFICE 
select 
distinct count(sales_agent) over(partition by regional_office)sales_agents, regional_office 
from sales_teams
order by sales_agents desc;

select  
count(sales_agent) sales_agent_total
from sales_teams;

-- QST 3: HOW DOES THE TOTAL REVENUE GENERATED BY EACH SALES AGENT VARY
SELECT distinct sales_agent,
floor(sum(revenue) over())total_revenue, 
floor(sum(revenue) over(partition by sales_agent )) distribution 
from combined_data
order by distribution desc;

-- QST 4: WHAT IS THE DISTRIBUTION OF REVENUE ACROSS DIFFERENT PRODUCT AND SERIES 
SELECT distinct product,
floor(sum(revenue) over())total_revenue, 
floor(sum(revenue) over(partition by product )) revenue_distribution 
from combined_data
order by revenue_distribution desc;	

SELECT distinct series,
floor(sum(revenue) over())total_revenue, 
floor(sum(revenue) over(partition by series )) revenue_distribution 
from combined_data
order by revenue_distribution desc;

-- QST 5: HOW DOES THE TOTAL REVENUE VARY OVERTIME
SELECT  distinct YEAR(engage_date) years,monthname(engage_date)month,
round(sum(revenue),2) total_revenue
from combined_data
where year(engage_date)<>''
group by years,month
order by total_revenue desc; 

-- QST 6: ARE THERE ANY PATTERN IN THE SALES TEAM PERFORMANCE BASED ON THE PRODUCT THEY SELL IN THEIR REGIONL OFFICE THEY BELONG TO
SELECT  sales_agent,product,regional_office,
sum(close_value) over( partition by sales_agent,product,regional_office)total_sales,
sum(close_value) over( partition by product,regional_office)ptotal_sales,
round(avg(close_value) over(partition by product),2)avg_sales
from combined_data
group by sales_agent,product,regional_office;



	

