use Hospitality;
select*from fact_booking;
select*from dim_date;
select*from dim_hotels;
select*from dim_rooms;
select*from fact_agregated_booking;

# 1. total revenue for all bookings
SELECT SUM(revenue_realized) AS Total_Revenue_Realized,sum(revenue_generated)Total_revenue_generated FROM fact_booking;
 
# 2. total number of bookings -
 SELECT COUNT(booking_id) AS Total_Bookings FROM fact_booking;

# 3. Total Capacity -
select sum(capacity) Total_Capacity from fact_agregated_booking;

# 4. Total Successful Bookings-
 SELECT COUNT(booking_id) AS `Total Succesful Bookings` FROM fact_booking
WHERE booking_status = 'Checked Out' ;

# 5. #Occupancy % -
SELECT  SUM(capacity) AS Total_Capacity, SUM(successful_bookings) AS Total_Successful_Bookings,
concat(round((SUM(successful_bookings) / SUM(capacity))*100,2)," %") AS Occupancy_Percentage
FROM fact_agregated_booking;

# 6. Average Rating - 
SELECT max(ratings_given)Max_Rating,Min(ratings_given)Min_Rating,
ROUND(AVG (ratings_given),1) Average_rating 
FROM fact_booking where ratings_given>0;


# 7. No of Days -
SELECT max(date)Starting_date,
min(date)Ending_date,
datediff(max(date),
min(date))+1`Total no of Days`  
from dim_date;

select count(date) from dim_date;
select count(distinct check_in_date) from fact_booking;

# 8. Total cancelled bookings -
SELECT count(booking_status) `Total Cancelled Boking` from  fact_booking where booking_status = 'Cancelled';

# 9. Cancellation % -
SELECT COUNT(booking_id) AS Total_Bookings,
COUNT(CASE WHEN booking_status = 'Cancelled' THEN 1 END) AS Total_Cancelled_Bookings,
CONCAT(ROUND((COUNT(CASE WHEN booking_status = 'Cancelled' THEN 1 END) * 100.0) / COUNT(booking_id),2),' %') AS Cancellation_Rate
FROM fact_booking;

# 10.,#11. Total number of checked out , cancelled and now show in booking status - 
SELECT booking_status AS 'Booking Status',COUNT(*) AS 'Count'FROM fact_booking GROUP BY 1; 


# 12. No Show rate % -
SELECT COUNT(booking_id) AS Total_Bookings,
COUNT(CASE WHEN booking_status = 'No show' THEN 1 END) AS `Total No Show Bookings`,
CONCAT(ROUND((COUNT(CASE WHEN booking_status = 'No Show' THEN 1 END) * 100.0) / COUNT(booking_id),1),' %') AS `No Show Rate %`
FROM fact_booking;
 
select count(booking_status) as Total_Bookings,
concat(round((Count(case when booking_status = "No show"then 1 end)/count(booking_id))*100,1)," %")as 'No show rate'
 from fact_booking;


# 13 Booking % by Platform - 
SELECT booking_platform AS `Booking Platform`,
concat(round(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_booking),2)," %") AS 'Percentage'
FROM fact_booking GROUP BY booking_platform;

# 14. Booking % by Room Class
select dr.room_class,
concat(round((count(fb.booking_id)*100/(select count(*)from fact_booking)),2)," %") as "Booking % by Room class"
from fact_booking fb
join dim_rooms dr on fb.room_category = dr.room_id
group by 1;

select dr.room_class, (count(booking_id)/(select count(*)from fact_booking)*100)
FROM fact_booking fb join dim_rooms dr on fb.room_category = dr.room_id
GROUP BY room_class;

# 15. ADR (average daily rate)
select round((sum(revenue_realized)/count(*)),2)`Averege Daily Revenue` from fact_booking;


# 16. Realisation % -
SELECT COUNT(booking_id) AS Total_Bookings, 
COUNT(CASE WHEN booking_status = 'Checked out' THEN 1 END) AS Total_Succesful_Bookings,
CONCAT(ROUND((COUNT(CASE WHEN booking_status = 'checked out' THEN 1 END) * 100.0) / COUNT(booking_id),2),' %') AS `Realisation %` 
FROM fact_booking;

SELECT (1- (sum(CASE WHEN booking_status IN ("cancelled","no show") THEN 1 END)/count(*)))*100 as "Realisation %"
FROM fact_booking;


# 17. RevPAR - Revnue generated per available room (output was different in Excel)
select (select sum(revenue_realized) from fact_booking)/(select sum(capacity) from fact_agregated_booking) RevPAR; 


# 18. DBRN (Daily Booked Room Nights)-
select(select count(booking_status) from fact_booking)/(select count(date) from dim_date)DBRN;

# 19. DSRN (Daily Sellable Room Nights)-
select sum(capacity)/count(distinct check_in_date)DSRN from fact_agregated_booking;

# 20 . DURN (Daily Utilized Room Nights)-
select(COUNT(CASE WHEN booking_status = 'Checked out' THEN 1 END)/count(distinct check_in_date))DURN from fact_booking;




#21 . Revenue WoW % change
select year,week,current_week_revenue,prev_week_revenue,
concat(round(((current_week_revenue - prev_week_revenue) / prev_week_revenue) * 100,2),' %') revenue_growth_percentage
from(
select year(check_in_date) as year, week(check_in_date,0)+1 as week, sum(revenue_realized) as current_week_revenue,
lag(sum(revenue_realized)) over(order by year(check_in_date), week(check_in_date,0)+1) as prev_week_revenue
from fact_booking
group by year(check_in_date), week(check_in_date)+1
) as WeeklyData
order by year, week;
 
# 22. Occupancy WoW change % 
select year,week,current_week_total_occupancy,prev_week_occupancy,
concat(round(((current_week_total_occupancy- prev_week_occupancy) / prev_week_occupancy)*100,2)," %") occupancy_growth_percentage
 from (
select year(check_in_date) as year, week(check_in_date,0)+1 as week,
(concat(round((SUM(successful_bookings) * 100.0 / SUM(capacity)),2)," %")) as current_week_total_occupancy,
lag (concat(round((SUM(successful_bookings) * 100.0 / SUM(capacity)),2)," %"))
 over(order by year(check_in_date),  week(check_in_date,0)+1) as prev_week_occupancy
from fact_agregated_booking
group by year(check_in_date),  week(check_in_date,0)+1
) as OccupancyData order by year, week;

# 23. ADR WoW% change -
select year, week, average_daily_rate AS current_week_adr, prev_week_adr,
concat(round((((average_daily_rate - prev_week_adr) / prev_week_adr) * 100),2)," %") adr_growth_percentage
FROM (
select year(check_in_date) as year, week(check_in_date)+1 as week, SUM(revenue_realized) / count(booking_id) as average_daily_rate,
lag(sum(revenue_realized) / count(booking_id)) over (order by year(check_in_date), week(check_in_date)+1) as prev_week_adr
from fact_booking group by year(check_in_date), week(check_in_date)+1) as AdrData
order by year, week;


#24 RevPAR WoW change %
#  RevPAR wow %
SELECT r.year,r.week,r.total_revenue / c.total_capacity AS Current_week_RevPAR,
LAG(r.total_revenue / c.total_capacity) 
OVER (ORDER BY r.year, r.week) AS prev_week_RevPAR,
CONCAT(ROUND(((r.total_revenue / c.total_capacity - LAG(r.total_revenue / c.total_capacity) OVER (ORDER BY r.year, r.week)) 
      / LAG(r.total_revenue / c.total_capacity) OVER (ORDER BY r.year, r.week)) * 100, 2), " %") AS RevPAR_growth_percentage
FROM (
    select year(check_in_date) AS year,week(check_in_date) + 1 AS week,SUM(revenue_realized) AS total_revenue
    FROM fact_booking
    GROUP BY year(check_in_date), week(check_in_date) + 1) r
JOIN (
    SELECT year(check_in_date) AS year,week(check_in_date) + 1 AS week,SUM(capacity) AS total_capacity
    FROM fact_agregated_booking
    GROUP BY year(check_in_date), week(check_in_date) + 1) c
ON r.year = c.year AND r.week = c.week
ORDER BY r.year, r.week;	



#25 realisaltion wow%
select year, week ,Current_week_Realisation,Prev_week_Realisation,
    concat(round(((Current_week_Realisation - prev_week_Realisation) /prev_week_Realisation) * 100,2)," %")as Realisation_WoW_percentage
from (
select year(check_in_date) as year, week(check_in_date)+1 as week, 
concat(round((COUNT(case when booking_status = 'checked out' then 1 end)  / (count(booking_id))*100),2),' %')as Current_week_Realisation,
lag(concat(round((count(case when booking_status = 'checked out' then 1 end)  / (count(booking_id))*100),2),' %')) 
over (order by year(check_in_date), week(check_in_date)+1) as prev_week_Realisation
from fact_booking 
group by year(check_in_date), week(check_in_date)+1) as Realisation_Data
order by year, week;





#26. DSRN WoW change % - 
SELECT current.week_no + 1 as current_week, current.total_dsrn as total_dsrn,
previous.total_dsrn as previous_week_dsrn,
CONCAT(ROUND(((current.total_dsrn - previous.total_dsrn) / previous.total_dsrn) * 100, 2), "%") AS wow_total_dsrn
from 
    (select week(fact_agregated_booking.check_in_date) as week_no,
         sum(fact_booking.revenue_realized)/sum(fact_agregated_booking.successful_bookings) as total_dsrn
     from 
         fact_agregated_booking inner join fact_booking 
     on fact_booking.check_in_date = fact_agregated_booking.check_in_date
     group by week(fact_agregated_booking.check_in_date)) as current
left join (select week(fact_agregated_booking.check_in_date) as week_no,
	sum(fact_booking.revenue_realized)/ sum(fact_agregated_booking.successful_bookings) as total_dsrn
     from fact_agregated_booking inner join fact_booking 
     on fact_booking.check_in_date = fact_agregated_booking.check_in_date
     group by week(fact_agregated_booking.check_in_date)) as previous
on current.week_no = previous.week_no + 1
order by current.week_no;



# weekend and weekdays wise revenue and booking - 
SELECT dd.day_type AS Day_Type, COUNT(fb.booking_id) AS Total_Bookings,SUM(fb.revenue_generated) AS Total_Revenue
FROM fact_booking fb
JOIN dim_date dd ON fb.check_in_date = dd.date
WHERE fb.booking_status = 'Checked Out'
GROUP BY dd.day_type;



#Booking Platform analysis info-
select booking_platform, booking_status ,count(booking_status)`No of Booking` ,
sum(revenue_generated)revenue_generated,sum(revenue_realized)revenue_realized from fact_booking
group by 1,2 order by 1,5 desc;

#class wise count & revenue - 
select dr.room_class as Class,count(booking_id)Count_Booking,sum(fb.revenue_realized) as Revenue
from fact_booking fb 
join dim_rooms dr on dr.room_id = fb.room_category group by class;



#revenue by city and Hotel - 
select dh.city as City, dh.property_name as Hotel , sum(fb.revenue_realized)Revenue
from fact_booking fb
join dim_hotels dh on fb.property_id = dh.property_id group by 1,2 order by 1,3 desc; 

#-- Platform Wise Revenue -- 
select booking_platform,concat(round(sum(revenue_generated)/10000000,0),' Cr') as revenue from fact_booking
group by booking_platform 
order by 2 desc;





