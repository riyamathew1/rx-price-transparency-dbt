{#-
    TODO (PLAN.md, week 1, Tue Nov 17): normalize any NDC to the 11-digit 5-4-2 form.

    Goal
      Return an 11-character, digits-only NDC for any input NDC.

    Inputs you will meet
      - FDA NDC Directory: 10 digits WITH hyphens, in one of three layouts:
          4-4-2  e.g. 0093-5056-98
          5-3-2  e.g. 12345-678-90
          5-4-1  e.g. 12345-6789-0
      - NADAC and SDUD: already 11 digits, no hyphens, but stored as text (keep leading zeros!).
      - CMS MFP file: 11 digits WITH hyphens (5-4-2) and a separate NDC-9 column.

    Rule
      Pad the short segment with ONE leading zero so the result is 5-4-2, then drop the hyphens.
      Never cast an NDC to a number.

    Acceptance criteria
      - A unit test (models/intermediate/_intermediate__unit_tests.yml) covers all three layouts,
        an already-11-digit value, a null and a malformed value (what should it return?).
      - The custom generic test `is_valid_ndc_11` passes on every model that outputs an NDC.
      - Works on DuckDB and Snowflake (hint: split_part, lpad, regexp functions exist in both;
        if a function differs, use adapter.dispatch like macros/parse_mdy_date.sql).
-#}
{% macro normalize_ndc_to_11(column_name) -%}
    case
        when {{ column_name }} is null then null
        when regexp_matches({{ column_name }}, '^[0-9]{11}$') then {{ column_name }}
        when regexp_matches({{ column_name }}, '^[0-9]{4}-[0-9]{4}-[0-9]{2}$')
            then lpad(split_part({{ column_name }}, '-', 1), 5, '0')
              || split_part({{ column_name }}, '-', 2)
              || split_part({{ column_name }}, '-', 3)
        when regexp_matches({{ column_name }}, '^[0-9]{5}-[0-9]{3}-[0-9]{2}$')
            then split_part({{ column_name }}, '-', 1)
              || lpad(split_part({{ column_name }}, '-', 2),4,'0')
              || split_part({{ column_name }}, '-', 3)
        when regexp_matches({{ column_name }}, '^[0-9]{5}-[0-9]{4}-[0-9]{1}$')
            then split_part({{ column_name }}, '-', 1)
              || split_part({{ column_name }}, '-', 2)
              || lpad(split_part({{ column_name }}, '-', 3),2,'0')
        when regexp_matches({{ column_name }}, '^[0-9]{5}-[0-9]{4}-[0-9]{2}$')
            then split_part({{ column_name }}, '-', 1)
              || split_part({{ column_name }}, '-', 2)
              || split_part({{ column_name }}, '-', 3)
        else null
    end
{%- endmacro %}
