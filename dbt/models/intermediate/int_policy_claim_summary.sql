--The claims table has claim-level records.But for reporting, we need policy-level claim summary which we obtain using this model.

with claims as (

    select *
    from {{ ref('stg_claims') }}

),

claim_summary as (

    select
        policy_id,

        count(*) as claim_count,

        sum(claim_amount) as total_claim_amount,

        sum(paid_amount) as total_paid_claim_amount,

        avg(paid_amount) as avg_paid_claim_amount,

        max(paid_amount) as max_paid_claim_amount

    from claims
    group by policy_id

)

select *
from claim_summary