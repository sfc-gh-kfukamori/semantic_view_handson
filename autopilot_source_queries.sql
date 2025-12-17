--- optional - if this is not your first time running through this lab, you may want to run this command before creating your HR_SEMANTIC_VIEW
-- USE ROLE agentic_analytics_vhol_role;
-- USE DATABASE SV_VHOL_DB;
-- USE SCHEMA VHOL_SCHEMA;

-- DROP SEMANTIC VIEW HR_SEMANTIC_VIEW;


-- セマンティックビューオートパイロット（SVA）からセマンティックビューを作成する。
-- HR_SEMANTIC_VIEWという人事領域向けの意味解釈レイヤー
-- サンプルSQLから自動で生成する


//Q1 
//従業員、部門、場所にわたる完全な人員内訳レポートを表示してください
//
SELECT 
    -- Employee dimensions
    e.EMPLOYEE_KEY,
    e.EMPLOYEE_NAME,
    e.GENDER,
    e.HIRE_DATE,
    -- Department dimensions  
    d.DEPARTMENT_KEY,
    d.DEPARTMENT_NAME,
    -- Job dimensions
    j.JOB_KEY,
    j.JOB_TITLE,
    j.JOB_LEVEL,
    -- Location dimensions
    l.LOCATION_KEY,
    l.LOCATION_NAME,
    -- Fact metrics
    f.HR_FACT_ID,
    f.DATE as RECORD_DATE,
    EXTRACT(YEAR FROM f.DATE) as RECORD_YEAR,
    EXTRACT(MONTH FROM f.DATE) as RECORD_MONTH,
    f.SALARY as EMPLOYEE_SALARY,
    f.ATTRITION_FLAG,
    -- Aggregated metrics
    COUNT(*) as EMPLOYEE_RECORD,
    SUM(f.SALARY) as TOTAL_SALARY_COST,
    AVG(f.SALARY) as AVG_SALARY,
    SUM(f.ATTRITION_FLAG) as ATTRITION_COUNT,
    COUNT(DISTINCT f.EMPLOYEE_KEY) as TOTAL_EMPLOYEES
FROM SV_VHOL_DB.VHOL_SCHEMA.HR_EMPLOYEE_FACT f
JOIN SV_VHOL_DB.VHOL_SCHEMA.EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
JOIN SV_VHOL_DB.VHOL_SCHEMA.DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
JOIN SV_VHOL_DB.VHOL_SCHEMA.JOB_DIM j 
    ON f.JOB_KEY = j.JOB_KEY
JOIN SV_VHOL_DB.VHOL_SCHEMA.LOCATION_DIM l 
    ON f.LOCATION_KEY = l.LOCATION_KEY
GROUP BY 
    e.EMPLOYEE_KEY, e.EMPLOYEE_NAME, e.GENDER, e.HIRE_DATE,
    d.DEPARTMENT_KEY, d.DEPARTMENT_NAME,
    j.JOB_KEY, j.JOB_TITLE, j.JOB_LEVEL,
    l.LOCATION_KEY, l.LOCATION_NAME,
    f.HR_FACT_ID, f.DATE, f.SALARY, f.ATTRITION_FLAG
ORDER BY f.DATE DESC, f.SALARY DESC;


//Q2
//給与指標と離職率指標を使用して、長期にわたる部門レベルの分析を提供してください
SELECT 
    d.DEPARTMENT_KEY,
    d.DEPARTMENT_NAME,
    EXTRACT(YEAR FROM f.DATE) as RECORD_YEAR,
    EXTRACT(MONTH FROM f.DATE) as RECORD_MONTH,
    -- Employee metrics
    COUNT(DISTINCT f.EMPLOYEE_KEY) as TOTAL_EMPLOYEES,
    COUNT(DISTINCT CASE WHEN e.GENDER = 'F' THEN f.EMPLOYEE_KEY END) as FEMALE_EMPLOYEES,
    COUNT(DISTINCT CASE WHEN e.GENDER = 'M' THEN f.EMPLOYEE_KEY END) as MALE_EMPLOYEES,
    -- Salary metrics
    SUM(f.SALARY) as TOTAL_SALARY_COST,
    AVG(f.SALARY) as AVG_SALARY,
    MIN(f.SALARY) as MIN_SALARY,
    MAX(f.SALARY) as MAX_SALARY,
    -- Attrition metrics
    SUM(f.ATTRITION_FLAG) as ATTRITION_COUNT,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as ATTRITION_RATE_PCT,
    -- Tenure metrics
    AVG(DATEDIFF('month', e.HIRE_DATE, f.DATE)) as AVG_TENURE_MONTHS,
    AVG(DATEDIFF('day', e.HIRE_DATE, f.DATE)) as AVG_TENURE_DAYS
FROM SV_VHOL_DB.VHOL_SCHEMA.HR_EMPLOYEE_FACT f
JOIN SV_VHOL_DB.VHOL_SCHEMA.DEPARTMENT_DIM d 
    ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY
JOIN SV_VHOL_DB.VHOL_SCHEMA.EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY d.DEPARTMENT_KEY, d.DEPARTMENT_NAME, EXTRACT(YEAR FROM f.DATE), EXTRACT(MONTH FROM f.DATE)
ORDER BY d.DEPARTMENT_NAME, RECORD_YEAR, RECORD_MONTH;


//Q3
//給与指標を使用して、長期にわたる求人と勤務地の分析を提供してください
SELECT 
    j.JOB_KEY,
    j.JOB_TITLE,
    j.JOB_LEVEL,
    l.LOCATION_KEY,
    l.LOCATION_NAME,
    EXTRACT(YEAR FROM f.DATE) as RECORD_YEAR,
    -- Employee counts by job and location
    COUNT(DISTINCT f.EMPLOYEE_KEY) as TOTAL_EMPLOYEES,
    COUNT(DISTINCT CASE WHEN e.GENDER = 'F' THEN f.EMPLOYEE_KEY END) as FEMALE_EMPLOYEES,
    COUNT(DISTINCT CASE WHEN e.GENDER = 'M' THEN f.EMPLOYEE_KEY END) as MALE_EMPLOYEES,
    -- Salary analysis
    SUM(f.SALARY) as TOTAL_SALARY_COST,
    AVG(f.SALARY) as AVG_SALARY,
    MIN(f.SALARY) as MIN_SALARY,
    MAX(f.SALARY) as MAX_SALARY,
    STDDEV(f.SALARY) as SALARY_STDDEV,
    -- Attrition analysis
    SUM(f.ATTRITION_FLAG) as ATTRITION_COUNT,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as ATTRITION_RATE_PCT,
    -- Tenure analysis
    AVG(DATEDIFF('month', e.HIRE_DATE, f.DATE)) as AVG_TENURE_MONTHS
FROM SV_VHOL_DB.VHOL_SCHEMA.HR_EMPLOYEE_FACT f
JOIN SV_VHOL_DB.VHOL_SCHEMA.JOB_DIM j 
    ON f.JOB_KEY = j.JOB_KEY
JOIN SV_VHOL_DB.VHOL_SCHEMA.LOCATION_DIM l 
    ON f.LOCATION_KEY = l.LOCATION_KEY
JOIN SV_VHOL_DB.VHOL_SCHEMA.EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY j.JOB_KEY, j.JOB_TITLE, j.JOB_LEVEL, l.LOCATION_KEY, l.LOCATION_NAME, EXTRACT(YEAR FROM f.DATE)
ORDER BY j.JOB_TITLE, l.LOCATION_NAME, RECORD_YEAR;

//Q4
//すべての主要な人事指標の長期的な傾向を表示してください
SELECT 
    EXTRACT(YEAR FROM f.DATE) as RECORD_YEAR,
    EXTRACT(MONTH FROM f.DATE) as RECORD_MONTH,
    f.DATE as RECORD_DATE,
    -- Employee metrics over time
    COUNT(DISTINCT f.EMPLOYEE_KEY) as TOTAL_EMPLOYEES,
    COUNT(DISTINCT f.DEPARTMENT_KEY) as TOTAL_DEPARTMENTS,
    COUNT(DISTINCT f.JOB_KEY) as TOTAL_JOBS,
    COUNT(DISTINCT f.LOCATION_KEY) as TOTAL_LOCATIONS,
    -- Salary trends
    SUM(f.SALARY) as TOTAL_SALARY_COST,
    AVG(f.SALARY) as AVG_SALARY,
    MIN(f.SALARY) as MIN_SALARY,
    MAX(f.SALARY) as MAX_SALARY,
    -- Attrition trends
    SUM(f.ATTRITION_FLAG) as ATTRITION_COUNT,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as ATTRITION_RATE_PCT,
    -- Gender distribution over time
    COUNT(DISTINCT CASE WHEN e.GENDER = 'F' THEN f.EMPLOYEE_KEY END) as FEMALE_EMPLOYEES,
    COUNT(DISTINCT CASE WHEN e.GENDER = 'M' THEN f.EMPLOYEE_KEY END) as MALE_EMPLOYEES,
    -- Tenure analysis over time
    AVG(DATEDIFF('month', e.HIRE_DATE, f.DATE)) as AVG_TENURE_MONTHS
FROM SV_VHOL_DB.VHOL_SCHEMA.HR_EMPLOYEE_FACT f
JOIN SV_VHOL_DB.VHOL_SCHEMA.EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY
GROUP BY EXTRACT(YEAR FROM f.DATE), EXTRACT(MONTH FROM f.DATE), f.DATE
ORDER BY RECORD_YEAR, RECORD_MONTH, RECORD_DATE;


//Q5
//すべての主要な指標を含むサマリーを提供してください
SELECT 
    'HR_ANALYTICS_SUMMARY' as REPORT_TYPE,
    -- Employee metrics
    COUNT(DISTINCT f.EMPLOYEE_KEY) as TOTAL_EMPLOYEES,
    COUNT(DISTINCT f.DEPARTMENT_KEY) as TOTAL_DEPARTMENTS,
    COUNT(DISTINCT f.JOB_KEY) as TOTAL_JOBS,
    COUNT(DISTINCT f.LOCATION_KEY) as TOTAL_LOCATIONS,
    -- Salary metrics
    SUM(f.SALARY) as TOTAL_SALARY_COST,
    AVG(f.SALARY) as AVG_SALARY,
    MIN(f.SALARY) as MIN_SALARY,
    MAX(f.SALARY) as MAX_SALARY,
    -- Attrition metrics
    SUM(f.ATTRITION_FLAG) as TOTAL_ATTRITION_COUNT,
    ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) as OVERALL_ATTRITION_RATE,
    -- Gender metrics
    COUNT(DISTINCT CASE WHEN e.GENDER = 'F' THEN f.EMPLOYEE_KEY END) as FEMALE_EMPLOYEES,
    COUNT(DISTINCT CASE WHEN e.GENDER = 'M' THEN f.EMPLOYEE_KEY END) as MALE_EMPLOYEES,
    ROUND(COUNT(DISTINCT CASE WHEN e.GENDER = 'F' THEN f.EMPLOYEE_KEY END) * 100.0 / 
          COUNT(DISTINCT f.EMPLOYEE_KEY), 2) as FEMALE_PERCENTAGE,
    -- Tenure metrics
    AVG(DATEDIFF('month', e.HIRE_DATE, f.DATE)) as AVG_TENURE_MONTHS,
    AVG(DATEDIFF('day', e.HIRE_DATE, f.DATE)) as AVG_TENURE_DAYS,
    -- Time range
    MIN(f.DATE) as EARLIEST_RECORD_DATE,
    MAX(f.DATE) as LATEST_RECORD_DATE
FROM SV_VHOL_DB.VHOL_SCHEMA.HR_EMPLOYEE_FACT f
JOIN SV_VHOL_DB.VHOL_SCHEMA.EMPLOYEE_DIM e 
    ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY;


show semantic views;

-- 作成されたセマンティックビューのDDLを取得
SELECT GET_DDL(
  'SEMANTIC_VIEW',
  'SV_VHOL_DB.VHOL_SCHEMA.HR_SEMANTIC_VIEW',
  TRUE
);


-- 作成されたセマンティックビューDDLをCopilotで日本語に変換

--DDLを貼り付けてみよう

--copilotで日本語のDDLへ変換
--以下のセマンティックビューを日本語に変換して。なお、with_extension内のverified queryの質問文も忘れずに日本語化すること。

--日本語化されたSemantic Viewで再作成

use role agentic_analytics_vhol_role;


-- Next --> Snowflake Notebooksでの作業へ

---バックアップSQL
-- create or replace semantic view SV_VHOL_DB.VHOL_SCHEMA.HR_SEMANTIC_VIEW
-- 	tables (
-- 		SV_VHOL_DB.VHOL_SCHEMA.LOCATION_DIM primary key (LOCATION_KEY) comment='このテーブルには拠点の記録が含まれています。各レコードは識別子と名前を持つ個別の拠点を表します。',
-- 		SV_VHOL_DB.VHOL_SCHEMA.JOB_DIM primary key (JOB_KEY) comment='このテーブルには職位とその分類の記録が含まれています。各レコードは組織内の固有の職名とその階層レベルを表します。',
-- 		SV_VHOL_DB.VHOL_SCHEMA.DEPARTMENT_DIM primary key (DEPARTMENT_KEY) comment='このテーブルには部門の参照情報が含まれています。各レコードは1つの部門とその識別情報を表します。',
-- 		SV_VHOL_DB.VHOL_SCHEMA.EMPLOYEE_DIM primary key (EMPLOYEE_KEY) comment='このテーブルには従業員とその基本プロフィール情報の記録が含まれています。各レコードは1人の従業員を表し、人口統計の詳細と雇用日を含みます。',
-- 		SV_VHOL_DB.VHOL_SCHEMA.HR_EMPLOYEE_FACT primary key (HR_FACT_ID) comment='このテーブルには給与と退職情報を含む従業員の記録が含まれています。各レコードは特定の時点における従業員の状況を表し、組織内の配置、報酬、および組織を去ったかどうかの情報を含みます。'
-- 	)
-- 	relationships (
-- 		HR_EMPLOYEE_FACT_TO_DEPARTMENT_DIM as HR_EMPLOYEE_FACT(DEPARTMENT_KEY) references DEPARTMENT_DIM(DEPARTMENT_KEY),
-- 		HR_EMPLOYEE_FACT_TO_EMPLOYEE_DIM as HR_EMPLOYEE_FACT(EMPLOYEE_KEY) references EMPLOYEE_DIM(EMPLOYEE_KEY),
-- 		HR_EMPLOYEE_FACT_TO_JOB_DIM as HR_EMPLOYEE_FACT(JOB_KEY) references JOB_DIM(JOB_KEY),
-- 		HR_EMPLOYEE_FACT_TO_LOCATION_DIM as HR_EMPLOYEE_FACT(LOCATION_KEY) references LOCATION_DIM(LOCATION_KEY)
-- 	)
-- 	facts (
-- 		HR_EMPLOYEE_FACT.SALARY as SALARY comment='米ドルでの年間基本給与。'
-- 	)
-- 	dimensions (
-- 		LOCATION_DIM.LOCATION_KEY as LOCATION_KEY comment='各拠点の一意の識別子。',
-- 		LOCATION_DIM.LOCATION_NAME as LOCATION_NAME comment='アメリカ合衆国内の市と州の名称。',
-- 		JOB_DIM.JOB_KEY as JOB_KEY comment='各職位の一意の識別子。',
-- 		JOB_DIM.JOB_LEVEL as JOB_LEVEL comment='組織内での職位の階層レベルまたはランク。',
-- 		JOB_DIM.JOB_TITLE as JOB_TITLE comment='組織内での専門的な職位または役割。',
-- 		DEPARTMENT_DIM.DEPARTMENT_KEY as DEPARTMENT_KEY comment='各部門の一意の識別子。',
-- 		DEPARTMENT_DIM.DEPARTMENT_NAME as DEPARTMENT_NAME comment='組織内のビジネス部門または機能単位の名称。',
-- 		EMPLOYEE_DIM.EMPLOYEE_KEY as EMPLOYEE_KEY comment='各従業員の一意の識別子。',
-- 		EMPLOYEE_DIM.EMPLOYEE_NAME as EMPLOYEE_NAME comment='従業員のフルネーム。',
-- 		EMPLOYEE_DIM.GENDER as GENDER comment='従業員の生物学的性別。',
-- 		EMPLOYEE_DIM.HIRE_DATE as HIRE_DATE comment='従業員が雇用された日付。',
-- 		HR_EMPLOYEE_FACT.ATTRITION_FLAG as ATTRITION_FLAG comment='従業員が組織を去ったかどうかを示すバイナリ指標。',
-- 		HR_EMPLOYEE_FACT.DEPARTMENT_KEY as DEPARTMENT_KEY comment='組織内の部門の一意の識別子。',
-- 		HR_EMPLOYEE_FACT.EMPLOYEE_KEY as EMPLOYEE_KEY comment='各従業員の一意の識別子。',
-- 		HR_EMPLOYEE_FACT.HR_FACT_ID as HR_FACT_ID comment='各人事記録の一意の識別子。',
-- 		HR_EMPLOYEE_FACT.JOB_KEY as JOB_KEY comment='組織内の職位の一意の識別子。',
-- 		HR_EMPLOYEE_FACT.LOCATION_KEY as LOCATION_KEY comment='従業員の勤務地の一意の識別子。',
-- 		HR_EMPLOYEE_FACT.DATE as DATE comment='従業員の記録が作成または更新された日付。'
-- 	)
-- 	with extension (CA='{"tables":[{"name":"LOCATION_DIM","dimensions":[{"name":"LOCATION_KEY","sample_values":["901","903","900"]},{"name":"LOCATION_NAME","sample_values":["Gavinside, NH","Smithview, WY","Yorkside, ME"]}]},{"name":"JOB_DIM","dimensions":[{"name":"JOB_KEY","sample_values":["802","800","801"]},{"name":"JOB_LEVEL"},{"name":"JOB_TITLE","sample_values":["Engineer","Data Analyst","HR Manager"]}]},{"name":"DEPARTMENT_DIM","dimensions":[{"name":"DEPARTMENT_KEY","sample_values":["12","11","31"]},{"name":"DEPARTMENT_NAME","sample_values":["Accounting","Treasury","Procurement"]}]},{"name":"EMPLOYEE_DIM","dimensions":[{"name":"EMPLOYEE_KEY","sample_values":["98","29","1"]},{"name":"EMPLOYEE_NAME","sample_values":["Fernando Braun","Troy Haney","Elizabeth George"]},{"name":"GENDER","sample_values":["M","F"]}],"time_dimensions":[{"name":"HIRE_DATE","sample_values":["2014-08-18","2018-02-24","2020-05-30"]}]},{"name":"HR_EMPLOYEE_FACT","dimensions":[{"name":"ATTRITION_FLAG","sample_values":["1","0"]},{"name":"DEPARTMENT_KEY","sample_values":["29","32","26"]},{"name":"EMPLOYEE_KEY","sample_values":["29","1","2"]},{"name":"HR_FACT_ID","sample_values":["98","29","1"]},{"name":"JOB_KEY","sample_values":["806","800","808"]},{"name":"LOCATION_KEY","sample_values":["907","908","906"]}],"facts":[{"name":"SALARY","sample_values":["69509.00","47652.00","53143.00"]}],"time_dimensions":[{"name":"DATE","sample_values":["2018-02-24","2019-08-18","2017-12-22"]}]}],"relationships":[{"name":"HR_EMPLOYEE_FACT_TO_DEPARTMENT_DIM","relationship_type":"many_to_one","join_type":"inner"},{"name":"HR_EMPLOYEE_FACT_TO_EMPLOYEE_DIM","relationship_type":"many_to_one","join_type":"inner"},{"name":"HR_EMPLOYEE_FACT_TO_JOB_DIM","relationship_type":"many_to_one","join_type":"inner"},{"name":"HR_EMPLOYEE_FACT_TO_LOCATION_DIM","relationship_type":"many_to_one","join_type":"inner"}],"verified_queries":[{"name":"0;1","question":"従業員数、多様性指標、給与統計、退職率、平均勤続年数を含む包括的な人事サマリーを提供できますか？","sql":"SELECT ''HR_ANALYTICS_SUMMARY'' AS REPORT_TYPE, COUNT(DISTINCT f.EMPLOYEE_KEY) AS TOTAL_EMPLOYEES /* Employee metrics */, COUNT(DISTINCT f.DEPARTMENT_KEY) AS TOTAL_DEPARTMENTS, COUNT(DISTINCT f.JOB_KEY) AS TOTAL_JOBS, COUNT(DISTINCT f.LOCATION_KEY) AS TOTAL_LOCATIONS, SUM(f.SALARY) AS TOTAL_SALARY_COST /* Salary metrics */, AVG(f.SALARY) AS AVG_SALARY, MIN(f.SALARY) AS MIN_SALARY, MAX(f.SALARY) AS MAX_SALARY, SUM(f.ATTRITION_FLAG) AS TOTAL_ATTRITION_COUNT /* Attrition metrics */, ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) AS OVERALL_ATTRITION_RATE, COUNT(DISTINCT CASE WHEN e.GENDER = ''F'' THEN f.EMPLOYEE_KEY END) AS FEMALE_EMPLOYEES /* Gender metrics */, COUNT(DISTINCT CASE WHEN e.GENDER = ''M'' THEN f.EMPLOYEE_KEY END) AS MALE_EMPLOYEES, ROUND(COUNT(DISTINCT CASE WHEN e.GENDER = ''F'' THEN f.EMPLOYEE_KEY END) * 100.0 / COUNT(DISTINCT f.EMPLOYEE_KEY), 2) AS FEMALE_PERCENTAGE, AVG(DATEDIFF(MONTH, e.HIRE_DATE, f.DATE)) AS AVG_TENURE_MONTHS /* Tenure metrics */, AVG(DATEDIFF(DAY, e.HIRE_DATE, f.DATE)) AS AVG_TENURE_DAYS, MIN(f.DATE) AS EARLIEST_RECORD_DATE /* Time range */, MAX(f.DATE) AS LATEST_RECORD_DATE FROM hr_employee_fact AS f JOIN employee_dim AS e ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY","verified_at":1765928028,"verified_by":"Semantic Model Generator"},{"name":"1;1","question":"従業員数、部門分布、報酬、退職、性別の多様性、平均勤続年数を含む主要な人事指標の経時的な傾向を教えてください。","sql":"SELECT DATE_PART(YEAR, f.DATE) AS RECORD_YEAR, DATE_PART(MONTH, f.DATE) AS RECORD_MONTH, f.DATE AS RECORD_DATE, COUNT(DISTINCT f.EMPLOYEE_KEY) AS TOTAL_EMPLOYEES /* Employee metrics over time */, COUNT(DISTINCT f.DEPARTMENT_KEY) AS TOTAL_DEPARTMENTS, COUNT(DISTINCT f.JOB_KEY) AS TOTAL_JOBS, COUNT(DISTINCT f.LOCATION_KEY) AS TOTAL_LOCATIONS, SUM(f.SALARY) AS TOTAL_SALARY_COST /* Salary trends */, AVG(f.SALARY) AS AVG_SALARY, MIN(f.SALARY) AS MIN_SALARY, MAX(f.SALARY) AS MAX_SALARY, SUM(f.ATTRITION_FLAG) AS ATTRITION_COUNT /* Attrition trends */, ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) AS ATTRITION_RATE_PCT, COUNT(DISTINCT CASE WHEN e.GENDER = ''F'' THEN f.EMPLOYEE_KEY END) AS FEMALE_EMPLOYEES /* Gender distribution over time */, COUNT(DISTINCT CASE WHEN e.GENDER = ''M'' THEN f.EMPLOYEE_KEY END) AS MALE_EMPLOYEES, AVG(DATEDIFF(MONTH, e.HIRE_DATE, f.DATE)) AS AVG_TENURE_MONTHS /* Tenure analysis over time */ FROM hr_employee_fact AS f JOIN employee_dim AS e ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY GROUP BY DATE_PART(YEAR, f.DATE), DATE_PART(MONTH, f.DATE), f.DATE ORDER BY RECORD_YEAR, RECORD_MONTH, RECORD_DATE","verified_at":1765928028,"verified_by":"Semantic Model Generator"},{"name":"2;1","question":"職務と勤務地別の従業員の人口統計、給与指標、退職率、平均勤続年数を含む包括的な労働力分析を提供できますか？","sql":"SELECT j.JOB_KEY, j.JOB_TITLE, j.JOB_LEVEL, l.LOCATION_KEY, l.LOCATION_NAME, DATE_PART(YEAR, f.DATE) AS RECORD_YEAR, COUNT(DISTINCT f.EMPLOYEE_KEY) AS TOTAL_EMPLOYEES /* Employee counts by job and location */, COUNT(DISTINCT CASE WHEN e.GENDER = ''F'' THEN f.EMPLOYEE_KEY END) AS FEMALE_EMPLOYEES, COUNT(DISTINCT CASE WHEN e.GENDER = ''M'' THEN f.EMPLOYEE_KEY END) AS MALE_EMPLOYEES, SUM(f.SALARY) AS TOTAL_SALARY_COST /* Salary analysis */, AVG(f.SALARY) AS AVG_SALARY, MIN(f.SALARY) AS MIN_SALARY, MAX(f.SALARY) AS MAX_SALARY, STDDEV(f.SALARY) AS SALARY_STDDEV, SUM(f.ATTRITION_FLAG) AS ATTRITION_COUNT /* Attrition analysis */, ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) AS ATTRITION_RATE_PCT, AVG(DATEDIFF(MONTH, e.HIRE_DATE, f.DATE)) AS AVG_TENURE_MONTHS /* Tenure analysis */ FROM hr_employee_fact AS f JOIN job_dim AS j ON f.JOB_KEY = j.JOB_KEY JOIN location_dim AS l ON f.LOCATION_KEY = l.LOCATION_KEY JOIN employee_dim AS e ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY GROUP BY j.JOB_KEY, j.JOB_TITLE, j.JOB_LEVEL, l.LOCATION_KEY, l.LOCATION_NAME, DATE_PART(YEAR, f.DATE) ORDER BY j.JOB_TITLE, l.LOCATION_NAME, RECORD_YEAR","verified_at":1765928028,"verified_by":"Semantic Model Generator"},{"name":"3;1","question":"性別ごとの従業員数、給与統計、退職率、平均勤続年数を含む月次の部門レベルの指標を教えてください。","sql":"SELECT d.DEPARTMENT_KEY, d.DEPARTMENT_NAME, DATE_PART(YEAR, f.DATE) AS RECORD_YEAR, DATE_PART(MONTH, f.DATE) AS RECORD_MONTH, COUNT(DISTINCT f.EMPLOYEE_KEY) AS TOTAL_EMPLOYEES /* Employee metrics */, COUNT(DISTINCT CASE WHEN e.GENDER = ''F'' THEN f.EMPLOYEE_KEY END) AS FEMALE_EMPLOYEES, COUNT(DISTINCT CASE WHEN e.GENDER = ''M'' THEN f.EMPLOYEE_KEY END) AS MALE_EMPLOYEES, SUM(f.SALARY) AS TOTAL_SALARY_COST /* Salary metrics */, AVG(f.SALARY) AS AVG_SALARY, MIN(f.SALARY) AS MIN_SALARY, MAX(f.SALARY) AS MAX_SALARY, SUM(f.ATTRITION_FLAG) AS ATTRITION_COUNT /* Attrition metrics */, ROUND(SUM(f.ATTRITION_FLAG) * 100.0 / COUNT(*), 2) AS ATTRITION_RATE_PCT, AVG(DATEDIFF(MONTH, e.HIRE_DATE, f.DATE)) AS AVG_TENURE_MONTHS /* Tenure metrics */, AVG(DATEDIFF(DAY, e.HIRE_DATE, f.DATE)) AS AVG_TENURE_DAYS FROM hr_employee_fact AS f JOIN department_dim AS d ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY JOIN employee_dim AS e ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY GROUP BY d.DEPARTMENT_KEY, d.DEPARTMENT_NAME, DATE_PART(YEAR, f.DATE), DATE_PART(MONTH, f.DATE) ORDER BY d.DEPARTMENT_NAME, RECORD_YEAR, RECORD_MONTH","verified_at":1765928028,"verified_by":"Semantic Model Generator"},{"name":"4;1","question":"部門、職務、勤務地にわたる従業員の分布、給与、退職に関する包括的な労働力分析を提供できますか？","sql":"SELECT e.EMPLOYEE_KEY /* Employee dimensions */, e.EMPLOYEE_NAME, e.GENDER, e.HIRE_DATE, d.DEPARTMENT_KEY /* Department dimensions  */, d.DEPARTMENT_NAME, j.JOB_KEY /* Job dimensions */, j.JOB_TITLE, j.JOB_LEVEL, l.LOCATION_KEY /* Location dimensions */, l.LOCATION_NAME, f.HR_FACT_ID /* Fact metrics */, f.DATE AS RECORD_DATE, DATE_PART(YEAR, f.DATE) AS RECORD_YEAR, DATE_PART(MONTH, f.DATE) AS RECORD_MONTH, f.SALARY AS EMPLOYEE_SALARY, f.ATTRITION_FLAG, COUNT(*) AS EMPLOYEE_RECORD /* Aggregated metrics */, SUM(f.SALARY) AS TOTAL_SALARY_COST, AVG(f.SALARY) AS AVG_SALARY, SUM(f.ATTRITION_FLAG) AS ATTRITION_COUNT, COUNT(DISTINCT f.EMPLOYEE_KEY) AS TOTAL_EMPLOYEES FROM hr_employee_fact AS f JOIN employee_dim AS e ON f.EMPLOYEE_KEY = e.EMPLOYEE_KEY JOIN department_dim AS d ON f.DEPARTMENT_KEY = d.DEPARTMENT_KEY JOIN job_dim AS j ON f.JOB_KEY = j.JOB_KEY JOIN location_dim AS l ON f.LOCATION_KEY = l.LOCATION_KEY GROUP BY e.EMPLOYEE_KEY, e.EMPLOYEE_NAME, e.GENDER, e.HIRE_DATE, d.DEPARTMENT_KEY, d.DEPARTMENT_NAME, j.JOB_KEY, j.JOB_TITLE, j.JOB_LEVEL, l.LOCATION_KEY, l.LOCATION_NAME, f.HR_FACT_ID, f.DATE, f.SALARY, f.ATTRITION_FLAG ORDER BY f.DATE DESC, f.SALARY DESC","verified_at":1765928028,"verified_by":"Semantic Model Generator"}]}');
