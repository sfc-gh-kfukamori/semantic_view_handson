-- Set role, database and schema
USE ROLE agentic_analytics_vhol_role;
USE DATABASE SV_VHOL_DB;
USE SCHEMA VHOL_SCHEMA;



SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
GROUP BY d.DEPARTMENT_NAME
ORDER BY employee_count DESC;

-- 2. Average Salary by Department and Gender
-- Business Question: "What is the average salary by department and gender?"
SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    e.GENDER,
    AVG(f.SALARY) as avg_salary,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY d.DEPARTMENT_NAME, e.GENDER
ORDER BY d.DEPARTMENT_NAME, e.GENDER;


SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    COUNT(*) as total_records,
    SUM(f.ATTRITION_FLAG) as attrition_count,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as attrition_rate_pct
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
GROUP BY d.DEPARTMENT_NAME
ORDER BY attrition_rate_pct DESC;


SELECT /* vhol_seed_query */
    EXTRACT(YEAR FROM f.DATE) as year,
    EXTRACT(MONTH FROM f.DATE) as month,
    AVG(f.SALARY) as avg_salary,
    MIN(f.SALARY) as min_salary,
    MAX(f.SALARY) as max_salary,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count
FROM HR_EMPLOYEE_FACT f
GROUP BY EXTRACT(YEAR FROM f.DATE), EXTRACT(MONTH FROM f.DATE)
ORDER BY year, month;


SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    AVG(DATEDIFF('day', e.HIRE_DATE, f.DATE)) as avg_tenure_days,
    AVG(DATEDIFF('month', e.HIRE_DATE, f.DATE)) as avg_tenure_months,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY d.DEPARTMENT_NAME
ORDER BY avg_tenure_days DESC;


SELECT /* vhol_seed_query */
    e.EMPLOYEE_NAME,
    d.DEPARTMENT_NAME,
    j.JOB_TITLE,
    f.SALARY,
    f.DATE as salary_date
FROM HR_EMPLOYEE_FACT f
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
JOIN JOB_DIM j 
    ON f.JOB_KEY = j.JOB_KEY
ORDER BY f.SALARY DESC
LIMIT 10;


SELECT /* vhol_seed_query */
    j.JOB_TITLE,
    j.JOB_LEVEL,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    AVG(f.SALARY) as avg_salary
FROM HR_EMPLOYEE_FACT f
JOIN JOB_DIM j 
    ON f.JOB_KEY = j.JOB_KEY
GROUP BY j.JOB_TITLE, j.JOB_LEVEL
ORDER BY j.JOB_LEVEL, employee_count DESC;


SELECT /* vhol_seed_query */
    l.LOCATION_NAME,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    AVG(f.SALARY) as avg_salary,
    SUM(f.ATTRITION_FLAG) as attrition_count
FROM HR_EMPLOYEE_FACT f
JOIN LOCATION_DIM l 
    ON f.LOCATION_KEY = l.LOCATION_KEY
GROUP BY l.LOCATION_NAME
ORDER BY employee_count DESC;


SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    e.GENDER,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    ROUND(COUNT(DISTINCT f.EMPLOYEE_KEY) * 100.0 / 
          SUM(COUNT(DISTINCT f.EMPLOYEE_KEY)) OVER (PARTITION BY d.DEPARTMENT_NAME), 2) as gender_pct
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY d.DEPARTMENT_NAME, e.GENDER
ORDER BY d.DEPARTMENT_NAME, e.GENDER;


SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    EXTRACT(YEAR FROM f.DATE) as year,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    AVG(f.SALARY) as avg_salary
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
GROUP BY d.DEPARTMENT_NAME, EXTRACT(YEAR FROM f.DATE)
ORDER BY d.DEPARTMENT_NAME, year;


SELECT /* vhol_seed_query */
    j.JOB_TITLE,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    MIN(f.SALARY) as min_salary,
    MAX(f.SALARY) as max_salary,
    AVG(f.SALARY) as avg_salary,
    STDDEV(f.SALARY) as salary_stddev
FROM HR_EMPLOYEE_FACT f
JOIN JOB_DIM j 
    ON f.JOB_KEY = j.JOB_KEY
GROUP BY j.JOB_TITLE
ORDER BY avg_salary DESC;


SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    SUM(f.SALARY) as total_salary_cost,
    AVG(f.SALARY) as avg_salary,
    MAX(f.SALARY) as max_salary,
    MIN(f.SALARY) as min_salary
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
GROUP BY d.DEPARTMENT_NAME
ORDER BY total_salary_cost DESC;


SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY f.SALARY) as p25_salary,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY f.SALARY) as p50_salary,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY f.SALARY) as p75_salary,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY f.SALARY) as p90_salary
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
GROUP BY d.DEPARTMENT_NAME
ORDER BY p50_salary DESC;


SELECT /* vhol_seed_query */
    j.JOB_LEVEL,
    j.JOB_TITLE,
    COUNT(*) as total_records,
    SUM(f.ATTRITION_FLAG) as attrition_count,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as attrition_rate_pct,
    AVG(f.SALARY) as avg_salary
FROM HR_EMPLOYEE_FACT f
JOIN JOB_DIM j 
    ON f.JOB_KEY = j.JOB_KEY
WHERE j.JOB_LEVEL IS NOT NULL
GROUP BY j.JOB_LEVEL, j.JOB_TITLE
ORDER BY attrition_rate_pct DESC;


SELECT /* vhol_seed_query */
    CASE 
        WHEN DATEDIFF('month', e.HIRE_DATE, f.DATE) <= 12 THEN 'Recent Hire (≤12 months)'
        WHEN DATEDIFF('month', e.HIRE_DATE, f.DATE) <= 24 THEN 'Mid-tenure (13-24 months)'
        ELSE 'Long-tenure (>24 months)'
    END as tenure_category,
    COUNT(*) as total_records,
    SUM(f.ATTRITION_FLAG) as attrition_count,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as attrition_rate_pct
FROM HR_EMPLOYEE_FACT f
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY tenure_category
ORDER BY attrition_rate_pct DESC;


SELECT /* vhol_seed_query */
    CASE 
        WHEN f.SALARY < 40000 THEN 'Low Salary (<40k)'
        WHEN f.SALARY < 60000 THEN 'Mid Salary (40k-60k)'
        ELSE 'High Salary (>60k)'
    END as salary_bracket,
    COUNT(*) as total_records,
    SUM(f.ATTRITION_FLAG) as attrition_count,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as attrition_rate_pct,
    AVG(f.SALARY) as avg_salary
FROM HR_EMPLOYEE_FACT f
GROUP BY salary_bracket
ORDER BY avg_salary;


SELECT /* vhol_seed_query */
    EXTRACT(YEAR FROM f.DATE) as year,
    EXTRACT(MONTH FROM f.DATE) as month,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as active_employees,
    SUM(f.ATTRITION_FLAG) as attrition_count,
    AVG(f.SALARY) as avg_salary
FROM HR_EMPLOYEE_FACT f
GROUP BY EXTRACT(YEAR FROM f.DATE), EXTRACT(MONTH FROM f.DATE)
ORDER BY year, month;


SELECT /* vhol_seed_query */
    EXTRACT(YEAR FROM f.DATE) as year,
    CASE 
        WHEN EXTRACT(MONTH FROM f.DATE) IN (1,2,3) THEN 'Q1'
        WHEN EXTRACT(MONTH FROM f.DATE) IN (4,5,6) THEN 'Q2'
        WHEN EXTRACT(MONTH FROM f.DATE) IN (7,8,9) THEN 'Q3'
        ELSE 'Q4'
    END as quarter,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    AVG(f.SALARY) as avg_salary,
    SUM(f.ATTRITION_FLAG) as attrition_count
FROM HR_EMPLOYEE_FACT f
GROUP BY EXTRACT(YEAR FROM f.DATE), quarter
ORDER BY year, quarter;


SELECT /* vhol_seed_query */
    f.EMPLOYEE_KEY,
    e.EMPLOYEE_NAME,
    COUNT(DISTINCT f.DEPARTMENT_KEY) as departments_worked,
    MIN(f.DATE) as first_date,
    MAX(f.DATE) as last_date,
    AVG(f.SALARY) as avg_salary
FROM HR_EMPLOYEE_FACT f
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY f.EMPLOYEE_KEY, e.EMPLOYEE_NAME
HAVING COUNT(DISTINCT f.DEPARTMENT_KEY) > 1
ORDER BY departments_worked DESC, avg_salary DESC;


SELECT /* vhol_seed_query */
    e.EMPLOYEE_NAME,
    d.DEPARTMENT_NAME,
    MIN(f.SALARY) as starting_salary,
    MAX(f.SALARY) as current_salary,
    MAX(f.SALARY) - MIN(f.SALARY) as salary_growth,
    ROUND((MAX(f.SALARY) - MIN(f.SALARY)) / MIN(f.SALARY) * 100, 2) as growth_pct
FROM HR_EMPLOYEE_FACT f
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
GROUP BY e.EMPLOYEE_NAME, d.DEPARTMENT_NAME
HAVING COUNT(*) > 1
ORDER BY growth_pct DESC;


SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as total_employees,
    COUNT(DISTINCT CASE WHEN e.GENDER = 'F' THEN f.EMPLOYEE_KEY END) as female_employees,
    COUNT(DISTINCT CASE WHEN e.GENDER = 'M' THEN f.EMPLOYEE_KEY END) as male_employees,
    ROUND(COUNT(DISTINCT CASE WHEN e.GENDER = 'F' THEN f.EMPLOYEE_KEY END) * 100.0 / 
          COUNT(DISTINCT f.EMPLOYEE_KEY), 2) as female_pct,
    AVG(f.SALARY) as avg_salary
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY d.DEPARTMENT_NAME
ORDER BY total_employees DESC;


SELECT /* vhol_seed_query */
    'Total Employees' as metric,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as value
FROM HR_EMPLOYEE_FACT f
WHERE f.DATE = (SELECT MAX(DATE) FROM HR_EMPLOYEE_FACT)

UNION ALL

SELECT 
    'Total Departments' as metric,
    COUNT(DISTINCT f.DEPARTMENT_KEY) as value
FROM HR_EMPLOYEE_FACT f
WHERE f.DATE = (SELECT MAX(DATE) FROM HR_EMPLOYEE_FACT)

UNION ALL

SELECT 
    'Average Salary' as metric,
    ROUND(AVG(f.SALARY), 2) as value
FROM HR_EMPLOYEE_FACT f
WHERE f.DATE = (SELECT MAX(DATE) FROM HR_EMPLOYEE_FACT)

UNION ALL

SELECT 
    'Total Attrition Count' as metric,
    SUM(f.ATTRITION_FLAG) as value
FROM HR_EMPLOYEE_FACT f
WHERE f.DATE = (SELECT MAX(DATE) FROM HR_EMPLOYEE_FACT);


SELECT /* vhol_seed_query */
    d.DEPARTMENT_NAME,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as employee_count,
    AVG(f.SALARY) as avg_salary,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as attrition_rate_pct,
    AVG(DATEDIFF('month', e.HIRE_DATE, f.DATE)) as avg_tenure_months,
    -- Health score: lower attrition + higher tenure + reasonable salary = healthier
    ROUND(
        (100 - ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2)) * 0.4 +
        LEAST(AVG(DATEDIFF('month', e.HIRE_DATE, f.DATE)) / 12, 10) * 0.3 +
        LEAST(AVG(f.SALARY) / 1000, 10) * 0.3, 2
    ) as health_score
FROM HR_EMPLOYEE_FACT f
JOIN DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
JOIN EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY d.DEPARTMENT_NAME
ORDER BY health_score DESC;

SELECT 1;

ALTER SESSION SET TIMEZONE = 'Asia/Tokyo';

SELECT 
query_text,
start_time
FROM Snowflake.account_usage.query_history
where query_text ilike '%d.DEPARTMENT_NAME%'
order by start_time desc
limit 100
;

