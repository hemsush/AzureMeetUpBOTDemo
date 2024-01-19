-- This script assumes the Cybersyn Financial Package has been installed at the default location
-- https://app.snowflake.com/marketplace/listing/GZTSZAS2KF7/cybersyn-inc-cybersyn-financial-economic-essentials

-- It creates two views:
-- SQLBOT_SAMPLE.CYBERSYN_FINANCIAL.FINANCIAL_ENTITY_ATTRIBUTES_LIMITED:
--    A subset of cybersyn_financial__economic_essentials.cybersyn.financial_institution_attributes:
--    Totals for assets, real estate loans, securities, deposits; % of deposits insured; total employees
-- SQLBOT_SAMPLE.CYBERSYN_FINANCIAL.FINANCIAL_ENTITY_ANNUAL_TIME_SERIES:
--    A modified version of cybersyn_financial__economic_essentials.cybersyn.financial_institution_timeseries as follows:
--    - Entity and attribute metadata is joined directly
--    - Only the set of attributes from FINANCIAL_ENTITY_ATTRIBUTES_LIMITED are exposed
--    - Only the end of year metrics (YYYY-12-31) are included, and a YEAR column is provided instead of the date column

-- Create a dedicated database and schema for the new views
CREATE DATABASE IF NOT EXISTS SQLBOT_SAMPLE;
CREATE SCHEMA IF NOT EXISTS SQLBOT_SAMPLE.CYBERSYN_FINANCIAL;

-- Create the limited attributes view
CREATE VIEW IF NOT EXISTS SQLBOT_SAMPLE.CYBERSYN_FINANCIAL.FINANCIAL_ENTITY_ATTRIBUTES_LIMITED AS
SELECT * from financial__economic_essentials.cybersyn.financial_institution_attributes
WHERE VARIABLE IN (
    'ASSET',
    'ESTINS',
    'LNRE',
    'DEP',
    -- 'NUMEMP', -- This seems to be multiplied by 1000x in the data set, which is awkward. Excluding for now.
    'SC'
);

-- Confirm the view was created correctly - should show 6 rows with variable name and definition
SELECT * FROM SQLBOT_SAMPLE.CYBERSYN_FINANCIAL.FINANCIAL_ENTITY_ATTRIBUTES_LIMITED;

-- Create the modified time series view
CREATE VIEW IF NOT EXISTS SQLBOT_SAMPLE.CYBERSYN_FINANCIAL.FINANCIAL_ENTITY_ANNUAL_TIME_SERIES AS
SELECT ent.name as entity_name, ent.city, ent.state_abbreviation,
ts.variable_name, year(ts.date) as "YEAR", to_double(ts.value) as value, ts.unit, att.definition
FROM financial__economic_essentials.cybersyn.financial_institution_timeseries AS ts
INNER JOIN SQLBOT_SAMPLE.CYBERSYN_FINANCIAL.FINANCIAL_ENTITY_ATTRIBUTES_LIMITED att ON (ts.variable = att.variable)
INNER JOIN financial__economic_essentials.cybersyn.financial_institution_entities AS ent ON (ts.id_rssd = ent.id_rssd)
WHERE MONTH(date) = 12 AND DAY(date) = 31;

-- Confirm the view was created correctly and view sample data
select * from SQLBOT_SAMPLE.CYBERSYN_FINANCIAL.FINANCIAL_ENTITY_ANNUAL_TIME_SERIES  limit 10;
