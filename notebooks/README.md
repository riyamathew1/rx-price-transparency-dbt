# notebooks/ (TODO, weeks 3-4)

dbt prepares the data, Python does the inference.

- `event_study.ipynb` (Sat Dec 5): read `mart_generic_entry_panel` from DuckDB
  (`duckdb.connect("rx.duckdb").sql("select * from dev_marts.mart_generic_entry_panel").df()`),
  estimate the event study with statsmodels (clustered standard errors by drug), plot it.
- `did_negotiated_prices.ipynb` (Sun Dec 6): the Jan 1, 2026 difference-in-differences.

Add `statsmodels`, `pandas`, `matplotlib` and `jupyter` to a separate `requirements-analysis.txt`
so CI stays light. Clear outputs before committing large notebooks.
