--CREATE DATABASE random;

--USE random;

-- Creating Fact Table
CREATE TABLE Human_resources (
    emp_id VARCHAR(50),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    birthdate VARCHAR(255),
    gender VARCHAR(255),
    race VARCHAR(50),
    department VARCHAR(50),
    jobtitle VARCHAR(255),
    location VARCHAR(255),
    hire_date VARCHAR(255),
    termdate VARCHAR(255),
    location_city VARCHAR(255),
    location_state VARCHAR(50)
);

COPY Human_resources FROM 'C:\Users\bansa\OneDrive\Desktop\HR_Analytics_PowerBI\Human_Resources.csv' WITH CSV HEADER DELIMITER ',';

ALTER TABLE human_resources
ALTER COLUMN emp_id TYPE VARCHAR(20),
ALTER COLUMN emp_id DROP NOT NULL;

UPDATE human_resources
SET birthdate = CASE
    WHEN birthdate LIKE '%-%' AND LENGTH(birthdate) = 10 THEN TO_CHAR(TO_DATE(birthdate, 'MM-DD-YYYY'), 'YYYY-MM-DD')
    WHEN birthdate LIKE '%-%' AND LENGTH(birthdate) = 9 THEN TO_CHAR(TO_DATE(birthdate, 'M-DD-YYYY'), 'YYYY-MM-DD')
    ELSE NULL
END;

ALTER TABLE human_resources ALTER COLUMN birthdate TYPE DATE USING birthdate::date;

UPDATE human_resources
SET hire_date = CASE
    WHEN hire_date LIKE '%-%' AND LENGTH(hire_date) = 10 THEN TO_CHAR(TO_DATE(hire_date, 'MM-DD-YYYY'), 'YYYY-MM-DD')
    WHEN hire_date LIKE '%-%' AND LENGTH(hire_date) = 9 THEN TO_CHAR(TO_DATE(hire_date, 'M-DD-YYYY'), 'YYYY-MM-DD')
    ELSE NULL
END;

ALTER TABLE human_resources ALTER COLUMN hire_date TYPE DATE USING hire_date::date;

UPDATE human_resources
SET termdate = TO_TIMESTAMP(termdate, 'YYYY-MM-DD HH24:MI:SS') 
WHERE termdate IS NOT NULL AND termdate != ' ';
ALTER TABLE human_resources
ALTER COLUMN termdate TYPE TIMESTAMP
USING termdate::timestamp without time zone;

ALTER TABLE human_resources ADD COLUMN age INT;

UPDATE human_resources
SET age = EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate));

ALTER TABLE human_resources RENAME TO Fact_Employee;

-- creating views
-- 1
CREATE VIEW age_distribution_view AS
SELECT
    gender,
    COUNT(*) AS count
FROM
    fact_employee
WHERE
    age >= 18
GROUP BY
    gender;

-- 2
CREATE VIEW age_distribution_by_race_view AS
SELECT
    race,
    COUNT(*) AS count
FROM
    fact_employee
WHERE
    age >= 18
GROUP BY
    race
ORDER BY
    count DESC;

-- 3
CREATE VIEW age_gender_distribution_view AS
SELECT 
    CASE 
        WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+' 
    END AS age_group,
    gender,
    COUNT(*) AS count
FROM 
    fact_employee
WHERE 
    age >= 18
GROUP BY 
    age_group, gender
ORDER BY 
    age_group, gender;

-- 4
CREATE VIEW location_distribution_view AS
SELECT 
    location,
    COUNT(*) AS count
FROM 
    fact_employee
WHERE 
    age >= 18
GROUP BY 
    location;

-- 5
CREATE VIEW avg_length_of_employment_view AS
SELECT 
    ROUND(AVG(EXTRACT(EPOCH FROM (termdate - hire_date)) / (60 * 60 * 24 * 365)), 0) AS avg_length_of_employment
FROM 
    fact_employee
WHERE 
    termdate IS NOT NULL
    AND termdate <= CURRENT_DATE
    AND age >= 18;

-- 6
CREATE VIEW department_gender_distribution_view AS
SELECT 
    department,
    gender,
    COUNT(*) AS count
FROM 
    fact_employee
WHERE 
    age >= 18
GROUP BY 
    department, gender
ORDER BY 
    department;

-- 7
CREATE VIEW jobtitle_distribution_view AS
SELECT 
    jobtitle,
    COUNT(*) AS count
FROM 
    fact_employee
WHERE 
    age >= 18
GROUP BY 
    jobtitle
ORDER BY 
    jobtitle DESC;

-- 8
CREATE VIEW department_termination_view AS
SELECT 
    department,
    COUNT(*) AS total_count,
    SUM(CASE WHEN termdate <= CURRENT_DATE AND termdate IS NOT NULL THEN 1 ELSE 0 END) AS terminated_count,
    SUM(CASE WHEN termdate IS NULL THEN 1 ELSE 0 END) AS active_count,
    CASE 
        WHEN COUNT(*) = 0 THEN NULL
        ELSE ROUND((SUM(CASE WHEN termdate <= CURRENT_DATE THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::numeric, 2)
    END AS termination_rate
FROM 
    fact_employee
WHERE 
    age >= 18
GROUP BY 
    department
ORDER BY 
    termination_rate DESC;

-- 9
CREATE VIEW location_state_distribution_view AS
SELECT 
    location_state,
    COUNT(*) AS count
FROM 
    fact_employee
WHERE 
    age >= 18
GROUP BY 
    location_state
ORDER BY 
    count DESC;

-- 10
CREATE VIEW annual_hiring_termination_view AS
SELECT 
    EXTRACT(YEAR FROM hire_date) AS year,
    COUNT(*) AS hires,
    SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURRENT_DATE THEN 1 ELSE 0 END) AS terminations,
    COUNT(*) - SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURRENT_DATE THEN 1 ELSE 0 END) AS net_change,
    ROUND(((COUNT(*) - SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURRENT_DATE THEN 1 ELSE 0 END)) * 100/ COUNT(*))::numeric,2) AS net_change_percent
FROM 
    fact_employee
WHERE 
    age >= 18
GROUP BY 
    EXTRACT(YEAR FROM hire_date)
ORDER BY 
    year ASC;

-- 11
CREATE VIEW avg_tenure_by_department_view AS
SELECT 
    department,
    ROUND(AVG(EXTRACT(EPOCH FROM (CURRENT_DATE - termdate)) / (60 * 60 * 24 * 365)), 0) as avg_tenure
FROM 
    fact_employee
WHERE 
    termdate IS NOT NULL
    AND termdate <= CURRENT_DATE
    AND termdate IS NOT NULL
    AND age >= 18
GROUP BY 
    department;