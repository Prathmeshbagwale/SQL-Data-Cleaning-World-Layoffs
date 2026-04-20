# 🧹 SQL Data Cleaning Project — World Layoffs Dataset

## 📌 Project Overview
This project demonstrates a complete data cleaning pipeline using **MySQL** on the 
World Layoffs dataset (2022–2023). The raw dataset contained duplicates, inconsistent 
formatting, null values, and incorrect data types — all resolved using structured SQL queries.

---

## 🗂️ Dataset
- **Source:** [Kaggle — Layoffs 2022](https://www.kaggle.com/datasets/swaptr/layoffs-2022)
- **Records:** ~2,360 rows
- **Columns:** Company, Location, Industry, Total Laid Off, Percentage Laid Off, 
Date, Stage, Country, Funds Raised (Millions)

---

## 🛠️ Tools Used
- MySQL 8.0
- MySQL Workbench

---

## 🔍 Problems Found in Raw Data

| Issue | Example | Fix Applied |
|---|---|---|
| Duplicate rows | Same company, same date, same layoffs | ROW_NUMBER() + staging table delete |
| Inconsistent industry names | 'Crypto', 'Crypto Currency', 'CryptoCurrency' | Standardized to 'Crypto' |
| Trailing punctuation in country | 'United States.' | TRIM(TRAILING '.') |
| Date stored as TEXT | '3/29/2023' (string) | STR_TO_DATE() + ALTER COLUMN |
| Blank industry fields | '' instead of NULL | Converted to NULL, filled via self-JOIN |
| Whitespace in company names | ' Airbnb' | TRIM() |
| Rows with no layoff data | Both total_laid_off AND percentage_laid_off NULL | Deleted — not useful for analysis |

---

## 🧱 Approach — Staging Table Strategy

To protect the original raw data, **all cleaning was done on copies**:
This ensures the original dataset is always recoverable — a best practice in 
professional data environments.

---

## 📋 Cleaning Steps

### Step 1 — Remove Duplicates
- Used `ROW_NUMBER() OVER(PARTITION BY ...)` to flag exact duplicate rows
- Iteratively refined PARTITION BY columns (discovered 'Oda' had 3 legitimately 
  different entries — verified before deleting)
- Attempted CTE delete (not supported in MySQL) → solved by inserting row_num 
  into staging2 and deleting where row_num > 1

### Step 2 — Standardize Data
- **Company:** Removed leading/trailing whitespace using `TRIM()`
- **Industry:** Unified 3 Crypto variants → 'Crypto' using `LIKE 'Crypto%'`
- **Country:** Removed trailing period from 'United States.' using `TRIM(TRAILING '.' FROM ...)`
- **Date:** Converted TEXT to DATE using `STR_TO_DATE('%m/%d/%Y')` + `ALTER TABLE MODIFY COLUMN`

### Step 3 — Handle NULL & Blank Values
- Converted blank industry strings to NULL first (required for JOIN logic to work)
- Used a **self-JOIN** to fill NULL industry values from other rows of the same company
- Example: Airbnb had NULL industry → filled as 'Travel' from another Airbnb row
- Bally's had only one row → no matching data available → kept as NULL (correct decision)
- Deleted rows where BOTH `total_laid_off` AND `percentage_laid_off` were NULL 
  (no analytical value)

### Step 4 — Remove Helper Columns
- Dropped `row_num` column after duplicate removal was complete

---

## 💡 Key SQL Concepts Demonstrated

- `ROW_NUMBER()` window function with `PARTITION BY`
- CTE (Common Table Expressions)
- Self-JOIN for NULL imputation
- `STR_TO_DATE()` and `ALTER TABLE MODIFY COLUMN`
- `TRIM()` and `TRIM(TRAILING ... FROM ...)`
- `INFORMATION_SCHEMA.COLUMNS` for metadata verification
- Staging table strategy for safe data manipulation
- `SQL_SAFE_UPDATES` toggle with explanation

---
## 👤 Author
**Prathmesh Murlidhar Bagwale**  
Data Analyst | B.Tech Mechanical Engineering — YCCE Nagpur  
📧 prathmeshbagwale@gmail.com  
🔗 [LinkedIn](https://linkedin.com/in/prathmesh-bagwale)

## 📚 Acknowledgements
Project built while following Alex Freberg's (Alex The Analyst) 
SQL Data Cleaning tutorial on YouTube as part of self-directed learning.
Dataset: Kaggle World Layoffs 2022.
