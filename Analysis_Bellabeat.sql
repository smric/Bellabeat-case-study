use Bellabeat
--checking number of users in dailyactivity merged table 
select COUNT(Distinct(Id))
from dailyActivity_merged
--checking number of users in sleepday merged table 
select COUNT(Distinct(Id))
from sleepDay_merged
--checking number of users in hourlysteps merged table 
select COUNT(Distinct(Id))
from hourlySteps_merged
--checking number of users in hourlycalories merged table 
select COUNT(Distinct(Id))
from hourlyCalories_merged
--- checking duplicates in dailyactivity merged table 
select Id,ActivityDate,TotalSteps,count(*)
from dailyActivity_merged
Group by Id,ActivityDate,TotalSteps
Having count(*) > 1 -- no duplicates 
--- checking duplicates in sleepday merged table 
select Id,SleepDay,TotalSleepRecords, count(*)
from sleepDay_merged
group by Id,SleepDay,TotalSleepRecords
having count(*) > 1; -- duplicates present 
--- checking duplicates in hourlysteps merged table 
select Id,ActivityHour,count(*)
from hourlySteps_merged
group by Id,ActivityHour,StepTotal
having count(*)>1; -- no duplicates 
--checking duplicates in hourlycalories merged table 
select Id,ActivityHour,Calories, count(*)
from hourlyCalories_merged
group by Id,ActivityHour,Calories
Having COUNT(*)>1 --duplicates present 
-- deleting duplicate records from sleepday merged table 
with CTE as(
	select distinct *
	from sleepDay_merged
)
select *
into new_sleepytable 
from CTE;
drop table sleepDay_merged
--deleting duplicate records from hourlycalories merged table 
with CTE as(
	select distinct *
	from hourlyCalories_merged
)
select *
into new_hourlycalories 
from CTE;
drop table hourlyCalories_merged
--changing data type and format hourlysteps_merged
update hourlySteps_merged
set ActivityHour = convert(datetime, ActivityHour, 101)
-- adding the day of week column in the dailyActvity merged table 
alter table dailyActivity_merged 
add day_of_week char(10)
Update dailyActivity_merged
set day_of_week = DATENAME(dw, ActivityDate)
-- adding the day of week column in the sleepday merged 
alter table sleepDay_merged 
add day_of_week char(10)
update new_sleepytable
set day_of_week = DATENAME(dw,SleepDay)
-- combining the dailyActivity merged and sleepDay merged tables together on Id and date columns to create a new table 
select t1.*,t2.TotalSleepRecords, t2.TotalMinutesAsleep, t2.TotalTimeInBed 
into daily_activity_sleep 
from dailyActivity_merged t1
inner join 
new_sleepytable t2
on
t1.id = t2.id AND t1.ActivityDate = t2.SleepDay;
--converting varchar to decimal columns in daily_activity_sleep 
alter table daily_activity_sleep
add new_TotalDistance decimal(10,2);
alter table daily_activity_sleep 
add new_TotalSteps decimal(10,2);
alter table daily_activity_sleep 
add new_TotalMinutesAsleep decimal(10,2);
alter table daily_activity_sleep 
add new_Calories decimal(10,2);
update daily_activity_sleep
set new_TotalDistance = CAST(TotalDistance as decimal(10,2));
update daily_activity_sleep
set new_TotalSteps = CAST(TotalSteps as decimal(10,2));
update daily_activity_sleep
set new_TotalMinutesAsleep = CAST(TotalMinutesAsleep as decimal(10,2));
update daily_activity_sleep
set new_Calories = CAST(Calories as decimal(10,2));
alter table daily_activity_sleep 
drop column TotalDistance;
alter table daily_activity_sleep 
drop column TotalSteps;
alter table daily_activity_sleep 
drop column TotalMinutesAsleep;
alter table daily_activity_sleep 
drop column Calories;
--average data by users 
SELECT id, round(avg(new_TotalDistance), 2) AS Avg_Distance, 
round(avg(new_TotalSteps), 2) AS Avg_Daily_Steps,
round(avg(new_TotalMinutesAsleep), 2) AS Avg_Sleep,
round(avg(new_Calories), 2) AS Avg_Calories
FROM
daily_activity_sleep
GROUP BY id; 
--average data by day of week 
select day_of_week, round(avg(new_TotalDistance), 2) AS Avg_Distance, 
round(avg(new_TotalSteps), 2) AS Avg_Daily_Steps,
round(avg(new_TotalMinutesAsleep), 2) AS Avg_Sleep,
round(avg(new_Calories), 2) AS Avg_Calories
from daily_activity_sleep
group by day_of_week
order by 
	case
		when day_of_week = 'Sunday' then 1
		when day_of_week = 'Monday' then 2
		when day_of_week = 'Tuesday' then 3
		when day_of_week = 'Wednesday' then 4
		when day_of_week = 'Thursday' then 5
		when day_of_week = 'Friday' then 6
		when day_of_week = 'Saturday' then 7
	end;
--total data by users 
select Id, round(sum(new_TotalDistance),2) as Total_Distance,
round(sum(new_TotalSteps),2) as Total_daily_steps, 
round(sum(new_TotalMinutesAsleep),2) as Total_sleep,
round(sum(new_Calories),2) as Total_Calories 
from daily_activity_sleep
group by Id;
--total data by day of week 
select day_of_week, round(sum(new_TotalDistance),2) as Total_Distance,
round(sum(new_TotalSteps),2) as Total_daily_steps, 
round(sum(new_TotalMinutesAsleep),2) as Total_sleep,
round(sum(new_Calories),2) as Total_Calories 
from daily_activity_sleep
group by day_of_week
order by 
	case
		when day_of_week = 'Sunday' then 1
		when day_of_week = 'Monday' then 2
		when day_of_week = 'Tuesday' then 3
		when day_of_week = 'Wednesday' then 4
		when day_of_week = 'Thursday' then 5
		when day_of_week = 'Friday' then 6
		when day_of_week = 'Saturday' then 7
	end;
--labelling users with respect to their avg_daily_steps 
SELECT id, round(avg(new_TotalDistance), 2) AS Avg_Distance, 
round(avg(new_TotalSteps), 2) AS Avg_Daily_Steps,
round(avg(new_TotalMinutesAsleep), 2) AS Avg_Sleep,
round(avg(new_Calories), 2) AS Avg_Calories
into average_by_user 
FROM daily_activity_sleep
GROUP BY id;
select Id,Avg_Daily_Steps,
(case 
when Avg_Daily_Steps < 5000 then 'Sedentary'
when Avg_Daily_Steps >= 5000 and Avg_Daily_Steps < 7499 then 'Lightly Active'
when Avg_Daily_Steps >= 7500 and Avg_Daily_Steps < 9999 then 'Fairly Active'
when Avg_Daily_Steps >= 10000 then 'Very Active'
end) as user_type
into labels_by_avg_daily_steps
from average_by_user
-- calculate percentage of different types of users based on average daily steps
select user_type, count(id) as total_users,
round((count(id)* 100)/24,2) as user_percentage
from labels_by_avg_daily_steps
group by user_type
--calculating average hourly steps throughout the day 
alter table hourlysteps_merged 
add time_of_day time;
update hourlySteps_merged
set time_of_day = cast(ActivityHour as time); 
alter table hourlysteps_merged 
add date_column date;
update hourlySteps_merged
set date_column = cast(ActivityHour as date);
alter table hourlySteps_merged 
add new_StepTotal decimal(10,2);
update hourlySteps_merged
set new_StepTotal = cast(StepTotal as decimal (10,2))
select time_of_day, round(avg(new_StepTotal),2) as average_steps 
from hourlySteps_merged
group by time_of_day; 
--calculating average calories through out the day 
alter table new_hourlycalories 
add new_Calories decimal(10,2);
update new_hourlycalories
set new_Calories = cast(Calories as decimal(10,2))
alter table new_hourlycalories
add Time_of_day time;
update new_hourlycalories
set Time_of_day = cast(ActivityHour as time);
select Time_of_day, round(avg(new_Calories),2) as average_calories 
from new_hourlycalories
group by Time_of_day;
--Calculating usage in days by users 
select id,count(id) as total_usage_in_days
into Frequency_of_usage 
from daily_activity_sleep
group by Id;
select Id,total_usage_in_days,
(case
when total_usage_in_days >=1 and total_usage_in_days <=10 then 'Low Use'
when total_usage_in_days >=11 and total_usage_in_days <=20 then 'Moderate Use'
when total_usage_in_days >=21 and total_usage_in_days <=31 then 'High Use'
end) as type_of_usage 
into lable_users_by_usage_in_days
from Frequency_of_usage
--calculating percentage of users based on users based on usage 
select type_of_usage, round((count(id)*100)/24,2) as type_of_usage_percentage 
from lable_users_by_usage_in_days
group by type_of_usage
--Total time spent on each activity per day 
alter table dailyActivity_merged 
add new_SedentaryMinutes decimal(10,2);
alter table dailyActivity_merged 
add new_LightlyActiveMinutes decimal(10,2);
alter table dailyActivity_merged 
add new_FairlyActiveMinutes decimal(10,2);
alter table dailyActivity_merged 
add new_VeryActiveMinutes decimal(10,2);
update dailyActivity_merged
set new_SedentaryMinutes = cast(SedentaryMinutes as decimal(10,2))
update dailyActivity_merged
set new_LightlyActiveMinutes = cast(LightlyActiveMinutes as decimal(10,2))
update dailyActivity_merged
set new_FairlyActiveMinutes = cast(FairlyActiveMinutes as decimal(10,2))
update dailyActivity_merged
set new_VeryActiveMinutes = cast(VeryActiveMinutes as decimal(10,2))
select day_of_week, sum(new_SedentaryMinutes) as Sedentary_mins, 
sum(new_LightlyActiveMinutes) as LightlyActive_mins, 
sum(new_FairlyActiveMinutes) as FairlyActive_mins,
sum(new_VeryActiveMinutes) as VeryActive_mins
from dailyActivity_merged
group by day_of_week
order by 
	case
		when day_of_week = 'Sunday' then 1
		when day_of_week = 'Monday' then 2
		when day_of_week = 'Tuesday' then 3
		when day_of_week = 'Wednesday' then 4
		when day_of_week = 'Thursday' then 5
		when day_of_week = 'Friday' then 6
		when day_of_week = 'Saturday' then 7
	end;
--total minutes each user spends on each activity 
select id,sum(new_SedentaryMinutes) as Sedentary_mins, 
sum(new_LightlyActiveMinutes) as LightlyActive_mins, 
sum(new_FairlyActiveMinutes) as FairlyActive_mins,
sum(new_VeryActiveMinutes) as VeryActive_mins
from dailyActivity_merged
group by Id;
-- percentage of total time spent on each activity per day 
SELECT
day_of_week,
round(sum(new_VeryActiveMinutes)/sum(new_VeryActiveMinutes+new_FairlyActiveMinutes+new_LightlyActiveMinutes+new_SedentaryMinutes)*100, 2) AS 'VAM',
round(sum(new_FairlyActiveMinutes)/sum(new_VeryActiveMinutes+new_FairlyActiveMinutes+new_LightlyActiveMinutes+new_SedentaryMinutes)*100, 2) AS 'FAM',
round(sum(new_LightlyActiveMinutes)/sum(new_VeryActiveMinutes+new_FairlyActiveMinutes+new_LightlyActiveMinutes+new_SedentaryMinutes)*100, 2)AS 'LAM',
round(sum(new_SedentaryMinutes)/sum(new_VeryActiveMinutes+new_FairlyActiveMinutes+new_LightlyActiveMinutes+new_SedentaryMinutes)*100, 2) AS 'SM'
FROM
dailyActivity_merged
GROUP BY day_of_week
order by 
	case
		when day_of_week = 'Sunday' then 1
		when day_of_week = 'Monday' then 2
		when day_of_week = 'Tuesday' then 3
		when day_of_week = 'Wednesday' then 4
		when day_of_week = 'Thursday' then 5
		when day_of_week = 'Friday' then 6
		when day_of_week = 'Saturday' then 7
	end;
-- percentage of users by amount of time users wore FitBit watch/device 
select t1.*, t2.total_usage_in_days, t2.type_of_usage
into daily_use 
from dailyActivity_merged t1
inner join lable_users_by_usage_in_days t2
on t1.Id = t2.Id
alter table daily_use 
add total_min_worn bigint
update daily_use
set total_min_worn = new_VeryActiveMinutes+new_FairlyActiveMinutes+new_LightlyActiveMinutes+new_SedentaryMinutes;
alter table daily_use 
add worn_type varchar(50)
update daily_use
set worn_type = case 
WHEN (total_min_worn*100/1440) = 100 Then 'All Day'
WHEN (total_min_worn*100/1440) < 100 AND (total_min_worn*100/1440) >= 50 Then 'More Than Half Day'
WHEN (total_min_worn*100/1440) < 50 AND (total_min_worn*100/1440) > 0 Then 'Less Than Half Day'
END;
select worn_type, count(id) as total_users, 
concat(round(count(id)*100/713,2),'%') AS worn_type_percentage
from daily_use
group by worn_type;
--correlation between dailysteps and calories 
select new_TotalSteps as Steps,new_Calories
from daily_activity_sleep
--correlation between dailysteps and minutes sleep 
select new_TotalSteps as Steps, new_TotalMinutesAsleep
from daily_activity_sleep












