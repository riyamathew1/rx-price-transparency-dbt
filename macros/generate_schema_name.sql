{#-
    Schema naming.

    - Production (target schema PROD): use the custom schema as-is, so models land in
      STAGING, INTERMEDIATE, MARTS and SNAPSHOTS, the schemas created by snowflake/setup.sql.
    - Everything else (dev, ci, pr_123): prefix with the target schema, e.g. dev_staging,
      so a developer or a pull request never overwrites production tables.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif default_schema | lower == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
