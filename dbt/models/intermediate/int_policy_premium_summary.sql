--The RAW_PREMIUMS table has payment-level records.Now, using this model will fetch only one record per policy(policy id)

with premiums as (

    select *
    from {{ ref('stg_premiums') }}

),

premium_summary as (

    select
        policy_id,

        sum(case
            when payment_status = 'Paid' then premium_amount
            else 0
        end) as total_paid_premium,

        sum(premium_amount) as total_billed_premium,

        count(*) as premium_payment_count,

        sum(case
            when payment_status in ('Late', 'Failed') then 1
            else 0
        end) as problem_payment_count

    from premiums
    group by policy_id

)

select *
from premium_summary