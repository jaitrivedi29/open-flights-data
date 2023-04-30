SQL Scripts: 

 

# 1. Demand analysis based on forecasting 
 
select C.Designid, demand, Acutal_orders,
case when demand <=(Acutal_orders*0.75) then 'Underestimated'
when demand>(Acutal_orders*1.25) then 'Overestimated'
else 'Correct Estimate'
end as Forecast_Accuracy
from catalogue as C
inner join
(
    SELECT designid, floor(avg(quantity)/3) as Acutal_orders
    FROM sudha_gold_industries.orders_catalogue
    group by 1
)as OC on OC.designid=C.designid


 

# 2. Pricing Analysis: 

select c.sub_group,price, avg(ocgroup.quant_ordered) as Average_orders
from catalogue c 
left join  
(
    select oc.DesignID , (oc.quantity) as quant_ordered
    from orders_catalogue oc 
) as ocgroup 
on 
c.DesignID=ocgroup.DesignID 
group by 1,2 
having Average_orders>0
order by 3 desc; 

 
#3. Top 10 Products by Volume 

SELECT a.designid as ID,UPPER(A.Sub_Group) as Product, SUM(B.QUANTITY) AS Orders 
FROM catalogue AS A 
LEFT JOIN  
( 

    SELECT DESIGNID, QUANTITY 
    FROM ORDERS_CATALOGUE 
) AS B  
ON B.DesignID=A.DESIGNID 
Where A.sub_group != 'OTHERS'
GROUP BY 1,2 
HAVING Orders>0 
ORDER BY 3 DESC 
LIMIT 10; 

  

#4. Top 10 Locations by Revenue 

Select  
case when location = 'Ananthapuram' or location = 'Anantapuram' then 'ANANTHAPURAM' else location 
end as City , 
sum(rev) as TOTAL_REV 
from  
( 

    select S.designid, location, s.sales_man_id,s.invoice_id, price
    *sale_quantity as Rev 
    from sales as S 
    left join  
    ( 

    select sales_man_id, invoiceid, location 
    from invoice 
    )as I
    on S.invoice_id = I.invoiceid 
    left join  
    ( 
        select designid, price 
        from catalogue 
    )as C 
    on C.designid= S.designid 
)as A  
where location is not null 
group by 1 
ORDER BY 2 DESC 
LIMIT 10; 

  

#5.Top 10 Buyers by Revenue 

  
Select party_name, sum(rev) as TOTAL_REV 
from  
( 
    select S.designid, party_name, s.sales_man_id,s.invoice_id, price*sale_quantity as Rev 
    from sales as S 
    left join  
    (   
        select sales_man_id, invoiceid, party_name 
        from invoice 
    )as I 
    on S.invoice_id = I.invoiceid 
left join  
    ( 
        select designid, price 
        from catalogue 
    )as C
    on C.designid= S.designid 
)as A  
where party_name is not null 
group by 1 
ORDER BY 2 DESC 
LIMIT 10; 

  

  
#6.Ranking Salesman By Revenue 

select A.sales_man_id, A.name, sum(price*sale_quantity) as Rev, rank() over (order by sum(price*sale_quantity) desc) as Ranking 
from salesman as A 
inner join 
( 

    Select * from  
    (	 
        Select B.designid, sales_man_id, sale_quantity, price 
        from sales 
        AS B   
        inner JOIN   
        (  
            SELECT Designid, price  
            from catalogue  
            where price>0  
        )AS C  
        ON B.DESIGNID = C.DESIGNID  
        where sale_quantity is not NULL 
    ) as C 
)B 
on A.sales_man_id = B.sales_man_id 
group by 1,2 
limit 10; 

 

#7. Top Sellingitem By SalesPerson

 
Select A.Name, A.Group ,Sold
from 
(
    Select Distinct *, rank() over (partition by A.name order by Sold desc) as Item_Index

    from 
    (
        select Distinct A.sales_man_id, A.name,B.group, sum(sale_quantity) over (partition by A.sales_man_id,b.group) as Sold 
        from salesman as A 
        inner join 
        ( 

            Select * from  
            (    
                Select B.designid, sales_man_id, C.Group ,sale_quantity
                from sales 
                AS B   
                inner JOIN   
                (  
                    SELECT Designid, Catalogue.Group  
                    from catalogue  
                    where price>0  
                )AS C  
                ON B.DESIGNID = C.DESIGNID  
                where sale_quantity >0 
            ) as C 
        )B 
        on A.sales_man_id = B.sales_man_id 
        where A.Name !='Shipped'
    )A
)A
where Item_Index =1
 

#8. Weekly Sales trends by month  

Select case 
when extract(month from date)=4 then'April'
when extract(month from date)=5 then'May' 
else 'June' end as Month,
case
when extract(day from date)<=7 then 'Week-1'
when extract(day from date)<=14 and extract(day from date)>7  then 'Week-2'
when extract(day from date)<=21 and extract(day from date)>14  then 'Week-3'
else 'Week-4' end as Week
,sum(top) as Revenue
from 
(
    select A.designid, date, (sale_quantity)*(price) as top
    from sales as A
    left join 
    (
        select designid, price
        from catalogue
    )B 
    on A.designid = B.designid
)C
group by 1,2 


#9 Top returned products by quantity >2000 

#top returned products to imporve   

select F.Group as Product_Type, sum(returns_processed) as Orders_Returned 
from 
( 
    SELECT S.designid, C.group, sum(-1*sale_quantity) as returns_processed  
    FROM sales as S 
    left join 
    ( 
        SELECT designid, description , Catalogue.Group  
        from catalogue 
    )C 
    on C.designid = S.designid 
    where sale_quantity <0 
    group by 1,2 
)F 
where F.group is not NULL 
group by 1 
having sum(returns_processed)>2000 
order by 2 desc; 

 

 
#10 Defects by months vs Total Orders 

#Defect frequency  

update sales set date = str_to_date(date, '%d-%m-%Y'); 

Select F.Month,F.Week, total_sold, (Returned/Total_Sold*100) as Return_Percentage 
from  
( 
    Select case  
    when extract(month from date)=4 then'April' 
    when extract(month from date)=5 then'May'  
    else 'June' end as Month, 
    case 
    when extract(day from date)<=7 then 'Week-1' 
    when extract(day from date)<=14 and extract(day from date)>7  then 'Week-2' 
    when extract(day from date)<=21 and extract(day from date)>14  then 'Week-3'    
    else 'Week-4' end as Week, 
    sum(-1*returns_processed) as Returned     
    from 
    ( 

        SELECT S.designid, s.date, C.group, sum(sale_quantity) as returns_processed  
        FROM sales as S 
        left join 
        ( 
            SELECT designid, description , Catalogue.Group  
            from catalogue 
        )C 
        on C.designid = S.designid 
        where sale_quantity <0 
        group by 1,2,3 
    )F 
    group by 1,2 
)F 
left join  
( 
    Select case  
    when extract(month from date)=4 then'April' 
    when extract(month from date)=5 then'May'  
    else 'June' end as Month, 
    case 
    when extract(day from date)<=7 then 'Week-1' 
    when extract(day from date)<=14 and extract(day from date)>7  then 'Week-2' 
    when extract(day from date)<=21 and extract(day from date)>14  then 'Week-3' 
    else 'Week-4' end as Week, 
    sum(sold) as Total_Sold 
    from 
    ( 
        SELECT S.designid, s.date, C.group, sum(sale_quantity) as sold  
        FROM sales as S 
        left join 
        ( 
            SELECT designid, description , Catalogue.Group  
            from catalogue 
        )C 
        on C.designid = S.designid 
    where sale_quantity >0 
    group by 1,2,3 
    )D 
group by 1,2 
)D 
on D.month = F.month and D.week=F.week ;

 

 

 

 