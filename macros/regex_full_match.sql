{% macro regex_full_match(column_name, pattern) -%}
    {{ return(adapter.dispatch('regex_full_match', 'rx_price_transparency')(column_name, pattern)) }}
{%- endmacro %}

{% macro default__regex_full_match(column_name, pattern) -%}
    regexp_like({{ column_name }}, '{{ pattern }}')
{%- endmacro %}

{% macro duckdb__regex_full_match(column_name, pattern) -%}
    regexp_matches({{ column_name }}, '{{ pattern }}')
{%- endmacro %}
