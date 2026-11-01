/* -- DATA CLEANING		(Remove /* to begin)

SELECT * FROM layoffs;

-- 1. Remove dupes
-- 2. Standardize the Data
-- 3. NULL values or blank values
-- 4. Remove Any columns that's irrelevant (Don't touch raw data set)

CREATE TABLE layoffs_stagging  -- Creates a Similar/ copy table column as layoffs
LIKE layoffs;

SELECT * FROM layoffs_stagging;  -- A small test

INSERT layoffs_stagging -- Insert every data from layoffs to layoffs_stagging
SELECT * FROM layoffs;

SELECT * FROM layoffs_stagging;

SELECT *,
ROW_NUMBER() OVER( PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions ) AS row_num
FROM layoffs_stagging;  -- IF row number shows up to be 2 or >2 there's duplicates. 1 being unique

WITH duplicate_cte AS -- DO this for better readability and it's better than sub query
(SELECT *,
ROW_NUMBER() OVER( PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions ) AS row_num
FROM layoffs_stagging)
SELECT * FROM duplicate_cte
WHERE row_num > 1; -- Should show 5 results where there's dupes

SELECT * FROM layoffs_stagging
WHERE company = "Casper";

WITH duplicate_cte AS
(SELECT *,
ROW_NUMBER() OVER( PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions ) AS row_num
FROM layoffs_stagging)
DELETE
FROM duplicate_cte
WHERE row_num > 1; 
 -- CANNOT update CTE, because not permanent
 
 -- CREATE a Second Identical table with row_num as addition, since DELETE doesn't work on CTE
 CREATE TABLE `layoffs_stagging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_stagging2;

INSERT INTO layoffs_stagging2
SELECT *,
ROW_NUMBER() OVER( PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions ) AS row_num
FROM layoffs_stagging;

SELECT * FROM layoffs_stagging2
WHERE row_num > 1;

-- Getting rid of duplicates
DELETE
FROM layoffs_stagging2
WHERE row_num > 1; 

-- standardizing data

SELECT company, TRIM(company)
FROM layoffs_stagging2;

UPDATE layoffs_stagging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_stagging2
ORDER BY industry;

SELECT * FROM layoffs_stagging2
WHERE industry LIKE "crypto%";

UPDATE layoffs_stagging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

SELECT DISTINCT Country
FROM layoffs_stagging2
ORDER by Country;

UPDATE layoffs_stagging2
SET country = "United States"
WHERE country LIKE "United States%";

SELECT `date`, str_to_date(`date`,"%m/%d/%Y")
FROM layoffs_stagging2;

UPDATE layoffs_stagging2
SET `date` = str_to_date(`date`,"%m/%d/%Y");

SELECT `date` FROM layoffs_stagging2;

ALTER TABLE layoffs_stagging2
MODIFY COLUMN `date` DATE;

-- Clean missing / NULL data

SELECT * FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
Order by company;

SELECT * from layoffs_stagging2
WHERE company = "Airbnb";

SELECT * FROM layoffs_stagging2 AS t1
JOIN layoffs_stagging2 AS t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE t1.industry IS NULL OR t1.industry = ""
AND t2.industry IS NOT NULL;

SELECT t1.company, t1.industry, t2.industry FROM layoffs_stagging2 AS t1
JOIN layoffs_stagging2 AS t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE t1.industry IS NULL OR t1.industry = ""
AND t2.industry IS NOT NULL;

UPDATE layoffs_stagging2
SET industry = NULL
WHERE industry ="";

UPDATE layoffs_stagging2 AS t1
JOIN layoffs_stagging2 AS t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT * FROM layoffs_stagging2;
-- WHERE company LIKE "Bally%";

DELETE FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_stagging2
DROP COLUMN row_num;

-- Exploratory Data Analysis

SELECT * FROM layoffs_stagging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_stagging2;

SELECT company, SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY company
ORDER BY SUM(total_laid_off) DESC;

-- shows beginning and ending time frame where layoffs occur
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_stagging2;


-- total layoff by country
SELECT country, SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY country
ORDER BY 2 DESC;

-- Summary of total lay off by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT stage, SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY stage
ORDER BY 2 DESC;

SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off)
FROM layoffs_stagging2
WHERE substring(`date`,1,7) IS NOT NULL
GROUP BY 1
ORDER BY 1 ASC;

 -- CTE
 WITH Rolling_Total AS
 (
 SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off) AS tlo
FROM layoffs_stagging2
WHERE substring(`date`,1,7) IS NOT NULL
GROUP BY 1
ORDER BY 1 ASC
)
SELECT `Month`, tlo, SUM(tlo) OVER(ORDER BY `Month`) AS rolling_total
FROM Rolling_total;

WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_stagging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5;

