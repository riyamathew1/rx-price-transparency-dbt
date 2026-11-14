{#- TODO (Week 2, Tue Nov 24, PLAN.md): custom generic test `no_overlapping_windows`
    Goal: Fail when two rows for the same key have overlapping [valid_from, valid_to) windows.
    A generic test is a SELECT that returns the FAILING rows (zero rows = pass).
    Done when: Applied to fct_nadac_price_history and the FDA snapshot.
    Then use it in YAML:  data_tests: [{no_overlapping_windows: {arguments: {...}}}]
-#}
{% test no_overlapping_windows(model, partition_by, valid_from, valid_to) %}
    {{ exceptions.raise_compiler_error('TODO: implement the no_overlapping_windows test (PLAN.md)') }}
{% endtest %}
