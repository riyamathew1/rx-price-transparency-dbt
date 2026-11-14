-- =============================================================================
-- snowflake/setup.sql: one-time setup for rx-price-transparency-dbt
--
-- TRIAL NOTE: the Snowflake trial for this project likely ends around Dec 3, 2026.
-- Do all Snowflake-only work (stage loading, warehouse tuning, slim CI) in weeks 1-3
-- of PLAN.md. After the trial, the DuckDB target keeps the whole project working for free.
--
-- Run it once in a Snowsight worksheet (Projects > Worksheets) as ACCOUNTADMIN,
-- top to bottom. It is idempotent (IF NOT EXISTS / OR REPLACE only where safe).
-- Nothing secret lives here; the CI user's PUBLIC key is pasted in by hand (optional, section 7).
--
-- Cost controls:
--   * one X-Small warehouse, AUTO_SUSPEND = 60 s, AUTO_RESUME, INITIALLY_SUSPENDED
--   * a 15-minute statement timeout so a runaway query cannot burn the trial
--   * a resource monitor that notifies at 50/75 %, suspends at 90 % and kills at 100 %
-- =============================================================================

use role accountadmin;

-- 1. Role -------------------------------------------------------------------
create role if not exists rx_transformer
    comment = 'dbt runs for rx-price-transparency-dbt (dev, CI and prod)';
grant role rx_transformer to role sysadmin;

set my_user = current_user();
grant role rx_transformer to user identifier($my_user);

-- 2. Warehouse --------------------------------------------------------------
create warehouse if not exists rx_wh
    warehouse_size = 'XSMALL'
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true
    statement_timeout_in_seconds = 900
    comment = 'rx-price-transparency-dbt; X-Small is enough for ~7M rows';

grant usage, operate on warehouse rx_wh to role rx_transformer;

-- 3. Resource monitor (needs ACCOUNTADMIN) -----------------------------------
-- An X-Small warehouse uses 1 credit per running hour. 20 credits is plenty for
-- this project through the end of the trial; raise it if a monitor suspends you.
create or replace resource monitor rx_monitor
    with credit_quota = 20
    frequency = monthly
    start_timestamp = immediately
    triggers
        on 50 percent do notify
        on 75 percent do notify
        on 90 percent do suspend
        on 100 percent do suspend_immediate;

alter warehouse rx_wh set resource_monitor = rx_monitor;

-- 4. Database and schemas ---------------------------------------------------
create database if not exists rx_prices
    comment = 'Drug price transparency: NADAC, SDUD, FDA NDC, CMS negotiated prices';

create schema if not exists rx_prices.raw
    comment = 'Landed files, every column as text. Loaded by snowflake/load_raw.sql';
create schema if not exists rx_prices.staging comment = 'dbt staging models (prod)';
create schema if not exists rx_prices.intermediate comment = 'dbt intermediate models (prod)';
create schema if not exists rx_prices.marts comment = 'dbt marts (prod)';
create schema if not exists rx_prices.snapshots comment = 'dbt snapshots (prod)';

-- dbt creates its own dev and pull-request schemas (dev_staging, pr_12_marts, ...),
-- so the role needs CREATE SCHEMA on the database.
grant usage, create schema on database rx_prices to role rx_transformer;
grant ownership on schema rx_prices.raw to role rx_transformer copy current grants;
grant ownership on schema rx_prices.staging to role rx_transformer copy current grants;
grant ownership on schema rx_prices.intermediate to role rx_transformer copy current grants;
grant ownership on schema rx_prices.marts to role rx_transformer copy current grants;
grant ownership on schema rx_prices.snapshots to role rx_transformer copy current grants;

-- 5. File formats and internal stage (owned by the dbt role) -----------------
use role rx_transformer;
use warehouse rx_wh;
use schema rx_prices.raw;

-- data.medicaid.gov and CMS files: comma separated, quoted, one header row.
create file format if not exists rx_prices.raw.csv_comma
    type = csv
    field_delimiter = ','
    skip_header = 1
    field_optionally_enclosed_by = '"'
    empty_field_as_null = true
    trim_space = false
    encoding = 'UTF8'
    error_on_column_count_mismatch = true
    comment = 'NADAC, SDUD, First Time NADAC, CMS MFP';

-- FDA NDC Directory: tab separated, no quoting (ingest/fda_ndc.py re-encodes to UTF-8).
create file format if not exists rx_prices.raw.tsv_fda
    type = csv
    field_delimiter = '\t'
    skip_header = 1
    field_optionally_enclosed_by = none
    empty_field_as_null = true
    encoding = 'UTF8'
    comment = 'FDA product.txt and package.txt';

create stage if not exists rx_prices.raw.raw_stage
    file_format = rx_prices.raw.csv_comma
    directory = (enable = true)
    comment = 'Internal stage. PUT files under nadac/, sdud/, fda_ndc/, cms_mfp/, nadac_first_time/';

-- 6. Future grants so new tables and views stay readable by the role ---------
use role accountadmin;
grant select on future tables in database rx_prices to role rx_transformer;
grant select on future views in database rx_prices to role rx_transformer;

-- 7. OPTIONAL (week 3): a key-pair service user for GitHub Actions slim CI ----
-- Generate the key pair on YOUR laptop (never in the repo, never in chat):
--   openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.snowflake/rx_ci_key.p8 -nocrypt
--   openssl rsa -in ~/.snowflake/rx_ci_key.p8 -pubout -out ~/.snowflake/rx_ci_key.pub
-- Paste the PUBLIC key body (no header/footer lines) below, uncomment and run.
-- Then add the PRIVATE key file contents as the GitHub secret SNOWFLAKE_PRIVATE_KEY.
--
-- create user if not exists rx_ci
--     type = service
--     default_role = rx_transformer
--     default_warehouse = rx_wh
--     rsa_public_key = '<paste public key body here>'
--     comment = 'GitHub Actions slim CI for rx-price-transparency-dbt';
-- grant role rx_transformer to user rx_ci;

-- 8. Check -------------------------------------------------------------------
show warehouses like 'RX_WH';
show resource monitors like 'RX_MONITOR';
show schemas in database rx_prices;
