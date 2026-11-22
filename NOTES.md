# Notes

## Week 1 — FDA NDC packages (Nov 21, 2026)
Layout counts in stg_fda_ndc__packages (20,000 rows):
| Layout | Rows   | Distinct ndc_11 |
|--------|--------|-----------------|
| 4-4-2  | 17,252 | 17,252          |
| 5-3-2  | 2,208  | 2,208           |
| 5-4-1  | 540    | 540             |

- 86% of packages use 4-4-2, so a wrong pad on 4-4-2 would break most joins.
- Every ndc_11 is unique, so padding never made two packages collide.
- Tested with a malformed code (0003-0894-2): the macro returns null and not_null catches it.
