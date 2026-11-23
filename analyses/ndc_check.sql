select
    {{ normalize_ndc_to_11("'0093-5056-98'") }} as layout_442,   -- expect 00093505698
    {{ normalize_ndc_to_11("'12345-678-90'") }} as layout_532,   -- expect 12345067890
    {{ normalize_ndc_to_11("'12345-6789-0'") }} as layout_541,   -- expect 12345678900
    {{ normalize_ndc_to_11("'12345-6789-01'") }} as layout_542,   -- expect 12345678901
    {{ normalize_ndc_to_11("'00093505698'") }} as already_11,   -- expect 00093505698
    {{ normalize_ndc_to_11("null") }} as is_null,      -- expect NULL
    {{ normalize_ndc_to_11("'abc-123'") }} as malformed     -- expect NULL
