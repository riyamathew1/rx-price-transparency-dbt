{#-
    Parse an MM/DD/YYYY text date (the format used by every data.medicaid.gov CSV)
    into a DATE. Blank strings become null instead of failing.

    Cross-database: DuckDB and Snowflake spell this differently, so the macro uses
    adapter.dispatch. `default__` is the Snowflake version.

    Usage: {{ parse_mdy_date('effective_date') }}
-#}
{% macro parse_mdy_date(column_name) -%}
    {{ return(adapter.dispatch('parse_mdy_date', 'rx_price_transparency')(column_name)) }}
{%- endmacro %}

{% macro default__parse_mdy_date(column_name) -%}
    try_to_date(nullif(trim({{ column_name }}), ''), 'MM/DD/YYYY')
{%- endmacro %}

{% macro duckdb__parse_mdy_date(column_name) -%}
    cast(try_strptime(nullif(trim({{ column_name }}), ''), '%m/%d/%Y') as date)
{%- endmacro %}
