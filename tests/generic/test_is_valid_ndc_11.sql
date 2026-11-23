{#- TODO (Week 1, Tue Nov 17, PLAN.md): custom generic test `is_valid_ndc_11`
    Goal: Fail rows whose value is not exactly 11 digits (null handling: decide and document).
    Nulls will be skipped in this test because of the where filter 'not null' which will only return
    the rows that are not null.
    A generic test is a SELECT that returns the FAILING rows (zero rows = pass).
    Done when: Applied to every ndc_11 column; a deliberately bad fixture row makes it fail.
    Then use it in YAML:  data_tests: [{is_valid_ndc_11: {arguments: {...}}}]
-#}
{% test is_valid_ndc_11(model, column_name) %}
select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and not {{ regex_full_match(column_name, '^[0-9]{11}$') }}
{% endtest %}
