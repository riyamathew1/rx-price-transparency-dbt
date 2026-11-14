-- ============================================================================
-- TODO: Event study: price drops after first-generic launch
-- When:  Week 3, Sat Dec 5 (see PLAN.md)
-- ============================================================================
-- Goal
--   Average log NADAC (brand and molecule-level) by week relative to first-generic launch, staggered across launches.
--
-- Grain:  relative_week
-- Inputs:
--   - mart_generic_entry_panel
-- Materialization: analysis (compiled SQL feeds notebooks/event_study.ipynb)
--
-- Definition of done
--   [ ] Chart: price index vs relative week with 95% CIs (notebook, statsmodels, clustered by drug).
--   [ ] Headline: '% drop in acquisition cost N weeks after first generic entry', with N launches and CI.
--   [ ] Pre-trend check shown and discussed.
--
-- Hints
--   * Staggered timing: read about two-way fixed effects pitfalls (Sun & Abraham / Callaway & Sant'Anna).
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
