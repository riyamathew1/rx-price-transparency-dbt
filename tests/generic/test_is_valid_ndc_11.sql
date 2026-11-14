{#- TODO (Week 1, Tue Nov 17, PLAN.md): custom generic test `is_valid_ndc_11`
    Goal: Fail rows whose value is not exactly 11 digits (null handling: decide and document).
    A generic test is a SELECT that returns the FAILING rows (zero rows = pass).
    Done when: Applied to every ndc_11 column; a deliberately bad fixture row makes it fail.
    Then use it in YAML:  data_tests: [{is_valid_ndc_11: {arguments: {...}}}]
-#}
{% test is_valid_ndc_11(model, column_name) %}
    {{ exceptions.raise_compiler_error('TODO: implement the is_valid_ndc_11 test (PLAN.md)') }}
{% endtest %}
