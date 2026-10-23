-- 01_clean.sql
-- Purpose: build the modeling table from LendingClub accepted loans
-- Sample: Fully Paid / Charged Off, 36-month term, issued 2013-2015
-- Split: 2013-2014 = train, 2015 = test. Only application-time variables are kept.

CREATE OR REPLACE TABLE loans_clean AS
WITH base AS (
    SELECT *, CAST(strptime(issue_d, '%b-%Y') AS DATE) AS issue_date
    FROM 'data/processed/accepted_raw.parquet'
    WHERE loan_status IN ('Fully Paid', 'Charged Off')
      AND trim(term) = '36 months'
)
SELECT
    id,
    issue_date,
    year(issue_date) AS issue_year,
    CASE WHEN year(issue_date) <= 2014 THEN 'train' ELSE 'test' END AS split,
    CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END AS default_flag,
    TRY_CAST(loan_amnt AS DOUBLE) AS loan_amnt,
    purpose,
    initial_list_status,
    CASE WHEN emp_length IS NULL THEN NULL
         WHEN emp_length = '< 1 year' THEN 0
         WHEN emp_length = '10+ years' THEN 10
         ELSE TRY_CAST(regexp_extract(emp_length, '(\d+)', 1) AS INTEGER)
    END AS emp_length_yrs,
    home_ownership,
    TRY_CAST(annual_inc AS DOUBLE) AS annual_inc,
    verification_status,
    addr_state,
    TRY_CAST(dti AS DOUBLE) AS dti,
    (TRY_CAST(fico_range_low AS DOUBLE) + TRY_CAST(fico_range_high AS DOUBLE)) / 2.0 AS fico,
    TRY_CAST(delinq_2yrs AS DOUBLE) AS delinq_2yrs,
    TRY_CAST(inq_last_6mths AS DOUBLE) AS inq_last_6mths,
    TRY_CAST(mths_since_last_delinq AS DOUBLE) AS mths_since_last_delinq,
    TRY_CAST(mths_since_last_record AS DOUBLE) AS mths_since_last_record,
    TRY_CAST(open_acc AS DOUBLE) AS open_acc,
    TRY_CAST(total_acc AS DOUBLE) AS total_acc,
    TRY_CAST(pub_rec AS DOUBLE) AS pub_rec,
    TRY_CAST(pub_rec_bankruptcies AS DOUBLE) AS pub_rec_bankruptcies,
    TRY_CAST(revol_bal AS DOUBLE) AS revol_bal,
    TRY_CAST(replace(revol_util, '%', '') AS DOUBLE) AS revol_util,
    date_diff('month',
              CAST(strptime(earliest_cr_line, '%b-%Y') AS DATE),
              issue_date) AS credit_hist_months
FROM base
WHERE year(issue_date) BETWEEN 2013 AND 2015;
