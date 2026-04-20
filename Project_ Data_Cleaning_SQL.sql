-- I.DATA CLEANING

USE world_layoffs;
SELECT *
FROM layoffs;

-- 1. Remove duplicates
-- 2. Standardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Columns

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- 1.CLEANING

SELECT *,
ROW_NUMBER() OVER( 
PARTITION BY company, industry ,total_laid_off, percentage_laid_off, `date`) AS row_num 
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER( 
PARTITION BY company, industry ,total_laid_off, percentage_laid_off, `date`, country) AS row_num 
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- checking from duplicate to verify we use right comparing parameters

SELECT *
FROM layoffs_staging
WHERE company = 'oda'; # THIS ARE 3 DIFFERENT COMPAINES SO NOW WE USE ALL PARAMETERS TO COMPARE

-- AFTER INCLUDING ALL PARAMETER


WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER( 
PARTITION BY company, location, industry ,total_laid_off, percentage_laid_off, `date`, stage
,country, funds_raised_millions) AS row_num 
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- AGAIN check 
SELECT *
FROM layoffs_staging
WHERE company = 'Casper'; # this time we got right data now we will remove duplicates only

DELETE 
FROM duplicate_cte  # This doesn't work in MySQL
WHERE row_num > 1;

-- we cannot delete data from primary database as, it would create problems
-- so created a backup DB and perform all operations on it 

CREATE TABLE `layoffs_staging2` (
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

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER( 
PARTITION BY company, location, industry ,total_laid_off, percentage_laid_off, `date`, stage
,country, funds_raised_millions) AS row_num 
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE 
FROM layoffs_staging2
WHERE row_num > 1;


SELECT *
FROM layoffs_staging2; # NOW ALL DUPLICATES ARE REMOVED

-- II.Standardizing Data

-- 1. Company column
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- 2. Industry column
SELECT DISTINCT industry -- Crypto ,Crypto Currency,CryptoCurrency this is issue here all need to be same     
FROM layoffs_staging2
ORDER BY 1;

-- updating

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto' 
WHERE industry LIKE 'Crypto%';

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry # final checking, all good
FROM layoffs_staging2;

-- 3. location

SELECT DISTINCT location # checking, all good
FROM layoffs_staging2
ORDER BY 1;

-- 4.country
SELECT DISTINCT country # checking, United staes is repeated 
FROM layoffs_staging2 
ORDER BY 1;

SELECT * 
FROM layoffs_staging2 
WHERE country LIKE 'United States%'
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) # TRAILING = coming at end
FROM layoffs_staging2 
ORDER BY 1;

UPDATE layoffs_staging2 
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country # Final Checking, good job, No repeated values 
FROM layoffs_staging2 
ORDER BY 1;

-- 5. Date is text column in database ,need to  be updated

SELECT `date`
FROM layoffs_staging2 ;


SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') AS Date_ # Date formate in MYSQL, Case sensitive,here the date is in the formate of our database 
FROM layoffs_staging2; # STR_TO_DATE, change the date into sql standard format

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date` # checking,date is in standard format but showing data type as string yet
FROM layoffs_staging2 ;

ALTER TABLE layoffs_staging2 # risky sometimes always do on backup database
MODIFY COLUMN `date` DATE;

SELECT COLUMN_NAME, DATA_TYPE # still showing text so we check it by this
FROM INFORMATION_SCHEMA.COLUMNS # its a Mysql UI bug, this result show date as date so we can move forward
WHERE TABLE_NAME = 'layoffs_staging2' 
AND COLUMN_NAME = 'date';

-- III. Null and blank values

SELECT *
FROM layoffs_staging2;

-- 1. total_laid_off

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL #commom null in both are not usefull for us
AND percentage_laid_off IS NULL;

SELECT * # checking nulls in industry
FROM layoffs_staging2 # it shows airbnb and others having null
WHERE industry IS NULL
OR industry = '';

SELECT * # so we check airbnb,  we found it as travel indusrt from other fileds in airbnb
FROM layoffs_staging2 # so we need to replace null by travel industry rather than deleting it
WHERE company = 'Airbnb';# deleting may affect the data quality,so aviod it, untill very neccesary

-- UPDATING
SET SQL_SAFE_UPDATES = 0; #temporarily disabling safe mode
UPDATE layoffs_staging2 # converting all blanks to null first, otherwise it will not work
SET industry = NULL
WHERE TRIM(industry) = '';
SET SQL_SAFE_UPDATES = 1; #re-enabling

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
     ON t1.company = t2.company
	SET  t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

SELECT *  # now null is filled with industy but only baileys is remaining
FROM layoffs_staging2 
WHERE company = 'Airbnb';

SELECT * # so it is having single roe we dont have similar values to compare so we will keep it as it is
FROM layoffs_staging2 
WHERE company LIKE 'Bally%';

-- deleting unneccsary data

Select *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS Null;


DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS Null;

SELECT * 
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2 
DROP COLUMN row_num; 

-- Cleaning complete
-- Removed: X duplicate rows
-- Standardized: industry (Crypto), country (United States.), date format
-- Filled: NULL industry values via self-join
-- Dropped: rows where both total_laid_off and percentage_laid_off are NULL
-- Removed: row_num helper column



