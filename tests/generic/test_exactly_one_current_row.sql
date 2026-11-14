{#- TODO (Week 2, Tue Nov 24, PLAN.md): custom generic test `exactly_one_current_row`
    Goal: Fail keys with zero or more than one current row.
    A generic test is a SELECT that returns the FAILING rows (zero rows = pass).
    Done when: Applied to fct_nadac_price_history.
    Then use it in YAML:  data_tests: [{exactly_one_current_row: {arguments: {...}}}]
-#}
{% test exactly_one_current_row(model, partition_by, current_flag) %}
    {{ exceptions.raise_compiler_error('TODO: implement the exactly_one_current_row test (PLAN.md)') }}
{% endtest %}
