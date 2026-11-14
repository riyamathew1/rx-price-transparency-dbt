-- =============================================================================
-- snowflake/load_raw.sql: land data/raw/* files in RX_PRICES.RAW (PUT + COPY INTO)
--
-- Run from the repo root AFTER `python ingest/run_all.py` (or --sample), with the
-- Snowflake CLI (https://docs.snowflake.com/en/developer-guide/snowflake-cli):
--
--   snow sql -f snowflake/load_raw.sql -D "repo_root=$(pwd)" \
--       --account "$SNOWFLAKE_ACCOUNT" --user "$SNOWFLAKE_USER" --role RX_TRANSFORMER
--
-- PUT only works from a client (Snowflake CLI, SnowSQL, Python connector), not from
-- a Snowsight worksheet. In Snowsight you can upload files to the stage by hand instead
-- (Data > Databases > RX_PRICES > RAW > Stages > RAW_STAGE > + Files).
--
-- Every column lands as VARCHAR, exactly like ingest/load_duckdb.py, so the dbt
-- staging models are the only place types are decided. Same SQL on both engines.
--
-- Trial ends ~Dec 3, 2026: do this in week 1.
-- =============================================================================

use role rx_transformer;
use warehouse rx_wh;
use schema rx_prices.raw;

-- 1. Raw tables ---------------------------------------------------------------
create table if not exists rx_prices.raw.nadac_weekly (
    ndc_description varchar,
    ndc varchar,
    nadac_per_unit varchar,
    effective_date varchar,
    pricing_unit varchar,
    pharmacy_type_indicator varchar,
    otc varchar,
    explanation_code varchar,
    classification_for_rate_setting varchar,
    corresponding_generic_drug_nadac_per_unit varchar,
    corresponding_generic_drug_effective_date varchar,
    as_of_date varchar,
    _source_file varchar,
    _loaded_at timestamp_ltz default current_timestamp()
);

create table if not exists rx_prices.raw.nadac_first_time_rates (
    drug_product varchar,
    brief_indication_description varchar,
    drug_class varchar,
    package_size varchar,
    ncpdp_billing_unit_standard varchar,
    nadac_rate varchar,
    number_of_active_ndcs_within_the_rategroup_that_are_on_the_covered_outpatient_drug_file varchar,
    primary_reason_code varchar,
    as_of_date varchar,
    classification_for_rate_setting varchar,
    _source_file varchar,
    _loaded_at timestamp_ltz default current_timestamp()
);

create table if not exists rx_prices.raw.sdud_quarterly (
    utilization_type varchar,
    state varchar,
    ndc varchar,
    labeler_code varchar,
    product_code varchar,
    package_size varchar,
    year varchar,
    quarter varchar,
    suppression_used varchar,
    product_name varchar,
    units_reimbursed varchar,
    number_of_prescriptions varchar,
    total_amount_reimbursed varchar,
    medicaid_amount_reimbursed varchar,
    non_medicaid_amount_reimbursed varchar,
    _source_file varchar,
    _loaded_at timestamp_ltz default current_timestamp()
);

create table if not exists rx_prices.raw.fda_ndc_product (
    productid varchar,
    productndc varchar,
    producttypename varchar,
    proprietaryname varchar,
    proprietarynamesuffix varchar,
    nonproprietaryname varchar,
    dosageformname varchar,
    routename varchar,
    startmarketingdate varchar,
    endmarketingdate varchar,
    marketingcategoryname varchar,
    applicationnumber varchar,
    labelername varchar,
    substancename varchar,
    active_numerator_strength varchar,
    active_ingred_unit varchar,
    pharm_classes varchar,
    deaschedule varchar,
    ndc_exclude_flag varchar,
    listing_record_certified_through varchar,
    _source_file varchar,
    _loaded_at timestamp_ltz default current_timestamp()
);

create table if not exists rx_prices.raw.fda_ndc_package (
    productid varchar,
    productndc varchar,
    ndcpackagecode varchar,
    packagedescription varchar,
    startmarketingdate varchar,
    endmarketingdate varchar,
    ndc_exclude_flag varchar,
    sample_package varchar,
    _source_file varchar,
    _loaded_at timestamp_ltz default current_timestamp()
);

create table if not exists rx_prices.raw.cms_mfp (
    ipay varchar,
    selected_drug_name varchar,
    active_ingredient_name_or_active_moiety_name varchar,
    ndc_9 varchar,
    ndc_11 varchar,
    xref_ndc_11 varchar,
    hcpcs_code varchar,
    mfp_effective_date varchar,
    mfp_end_date varchar,
    single_mfp_per_30_des varchar,
    ndc_9_mfp_per_unit_price varchar,
    hcpcs_code_dosage_price varchar,
    as_of_date varchar,
    type_of_update varchar,
    remarks varchar,
    _source_file varchar,
    _loaded_at timestamp_ltz default current_timestamp()
);

-- 2. Upload files to the internal stage -------------------------------------
-- AUTO_COMPRESS gzips on upload. OVERWRITE = FALSE skips files already on the stage
-- with the same name and content.
put 'file://<% repo_root %>/data/raw/nadac/*.csv' @rx_prices.raw.raw_stage/nadac/ auto_compress = true overwrite = false;
put 'file://<% repo_root %>/data/raw/nadac_first_time/*.csv' @rx_prices.raw.raw_stage/nadac_first_time/ auto_compress = true;
put 'file://<% repo_root %>/data/raw/sdud/*.csv' @rx_prices.raw.raw_stage/sdud/ auto_compress = true;
put 'file://<% repo_root %>/data/raw/fda_ndc/*.txt' @rx_prices.raw.raw_stage/fda_ndc/ auto_compress = true overwrite = true;
put 'file://<% repo_root %>/data/raw/cms_mfp/*.csv' @rx_prices.raw.raw_stage/cms_mfp/ auto_compress = true overwrite = true;

list @rx_prices.raw.raw_stage;

-- 3. COPY INTO: worked example for NADAC -------------------------------------
-- Positional columns ($1..$12) because the CSV headers have spaces ("NDC Description").
-- METADATA$FILENAME gives lineage back to the weekly file. COPY remembers which files it
-- loaded (for 64 days), so re-running this is safe: already-loaded files are skipped.
copy into rx_prices.raw.nadac_weekly (
    ndc_description,
    ndc,
    nadac_per_unit,
    effective_date,
    pricing_unit,
    pharmacy_type_indicator,
    otc,
    explanation_code,
    classification_for_rate_setting,
    corresponding_generic_drug_nadac_per_unit,
    corresponding_generic_drug_effective_date,
    as_of_date,
    _source_file,
    _loaded_at
)
from (
    select
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        $11,
        $12,
        metadata$filename,
        current_timestamp()
    from @rx_prices.raw.raw_stage/nadac/
)
file_format = (format_name = 'rx_prices.raw.csv_comma')
pattern = '.*nadac_[0-9]{4}[.]csv[.]gz'
on_error = abort_statement;

-- 4. TODO (PLAN.md, week 1, Sat Nov 21): write the COPY INTO for the other tables.
--   * sdud_quarterly: same pattern as NADAC. Then think about restatements: CMS re-publishes
--     a whole year under a NEW file name, and COPY will happily load both versions. How will
--     you keep only the latest file per year? (Hint: _source_file, and the merge in
--     models/intermediate/int_sdud__restated.sql.) Try `force = true` and see what happens.
--   * fda_ndc_product / fda_ndc_package: use file_format rx_prices.raw.tsv_fda. The FDA file is a
--     full daily replacement, so TRUNCATE before COPY (and let the dbt snapshot keep history).
--   * cms_mfp and nadac_first_time_rates: small, full replacement each time.
--   Check each load with: select * from table(validate(<table>, job_id => '_last'));

-- 5. Check ----------------------------------------------------------------------
select 'nadac_weekly' as table_name, count(*) as row_count from rx_prices.raw.nadac_weekly
union all select 'sdud_quarterly', count(*) from rx_prices.raw.sdud_quarterly
union all select 'fda_ndc_product', count(*) from rx_prices.raw.fda_ndc_product
union all select 'fda_ndc_package', count(*) from rx_prices.raw.fda_ndc_package
union all select 'cms_mfp', count(*) from rx_prices.raw.cms_mfp
union all select 'nadac_first_time_rates', count(*) from rx_prices.raw.nadac_first_time_rates;
