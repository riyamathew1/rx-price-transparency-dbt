-- TODO (Week 2, Fri Nov 27, PLAN.md): singular reconciliation test.
-- Sum of state rows should be close to the national total (state = 'XX') for each
-- utilization type x NDC x quarter. Return the rows where the gap exceeds a tolerance
-- you justify (suppressed small states make it inexact).
-- Done when it runs green on Snowflake with SDUD 2024-2025, and the tolerance is in the README.
{{ config(enabled=false) }}

select 1 as todo
