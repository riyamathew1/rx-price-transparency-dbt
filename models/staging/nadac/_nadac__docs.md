{% docs nadac_as_of_vs_effective %}
NADAC rows carry two dates, which makes the price history **bitemporal**:

- `effective_date` (valid time): the day the rate started applying in the real world.
- `as_of_date` (transaction / knowledge time): the weekly file in which CMS published the row.

The same `(ndc_11, effective_date, nadac_per_unit)` normally repeats every Wednesday until the
rate changes, so most weekly rows are not new information. A handful of rows have an
`effective_date` *after* their `as_of_date` (36 in the 2026 file on Nov 14, 2026), which is
why the ordering check below is a warning, not an error. Turning this into an SCD Type 2 table
is the main exercise in week 2 of PLAN.md.
{% enddocs %}

{% docs nadac_pricing_unit %}
NADAC is a price **per pricing unit**, not per package or per prescription:
`EA` (each: tablet, capsule, patch), `ML` (liquids, injectables) or `GM` (creams, ointments).
SDUD `units_reimbursed` uses the same NCPDP billing units, so `nadac_per_unit * units_reimbursed`
estimates acquisition cost, but only after you check the units really match (PLAN.md week 1).
{% enddocs %}
