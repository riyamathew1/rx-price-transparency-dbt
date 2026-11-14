-- Worked example of a staging model: one source, rename, cast, light cleanup, nothing else.
-- No joins, no filters, no business logic. Those belong in intermediate models.
-- Grain: one row per NDC per weekly publication (ndc_11 x as_of_date).

with

source as (

    select * from {{ source('nadac', 'weekly') }}

),

renamed as (

    select
        -- keys: NDC stays TEXT so the leading zeros survive
        lpad(trim(ndc), 11, '0') as ndc_11,
        {{ parse_mdy_date('as_of_date') }} as as_of_date,
        {{ parse_mdy_date('effective_date') }} as effective_date,

        -- descriptive attributes
        trim(ndc_description) as ndc_description,
        upper(trim(pricing_unit)) as pricing_unit,
        trim(pharmacy_type_indicator) as pharmacy_type_indicator,
        trim(classification_for_rate_setting) as rate_setting_class,
        trim(explanation_code) as explanation_codes,
        case upper(trim(otc))
            when 'Y' then true
            when 'N' then false
        end as is_otc,
        coalesce(trim(classification_for_rate_setting) like 'B%', false) as is_brand,

        -- measures (dollars per pricing unit)
        cast(nadac_per_unit as decimal(18, 5)) as nadac_per_unit,
        cast(
            nullif(trim(corresponding_generic_drug_nadac_per_unit), '') as decimal(18, 5)
        ) as corresponding_generic_nadac_per_unit,
        {{ parse_mdy_date('corresponding_generic_drug_effective_date') }}
            as corresponding_generic_effective_date,

        -- lineage
        _source_file,
        _loaded_at

    from source

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['ndc_11', 'as_of_date']) }} as nadac_weekly_id,
        *
    from renamed

)

select * from final
