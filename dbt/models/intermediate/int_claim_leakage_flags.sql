--This model checks each claim and creates warning flags.We will flag:
--duplicate claims
--claims after policy end date
--claims without premium payment
--high severity claims
--This is what makes the project stronger than a normal dashboard.

with claims as (

    select *
    from {{ ref('stg_claims') }}

),

policies as (

    select *
    from {{ ref('stg_policies') }}

),

premium_summary as (

    select *
    from {{ ref('int_policy_premium_summary') }}

),

claims_joined as (

    select
        c.claim_id,
        c.policy_id,
        p.customer_id,
        p.agent_id,
        p.policy_type,
        p.region,
        p.policy_start_date,
        p.policy_end_date,

        c.claim_date,
        c.claim_type,
        c.claim_status,
        c.claim_amount,
        c.paid_amount,
        c.claim_severity_level,

        coalesce(ps.total_paid_premium, 0) as total_paid_premium,

        count(*) over (
            partition by c.policy_id, c.claim_date, c.claim_type, c.claim_amount
        ) as possible_duplicate_count --This checks whether the same policy has the same claim date, claim type, and claim amount more than once.

    from claims c

    left join policies p
        on c.policy_id = p.policy_id

    left join premium_summary ps
        on c.policy_id = ps.policy_id

),

final as (

    select
        *,

        case
            when possible_duplicate_count > 1 then 1
            else 0
        end as duplicate_claim_flag,

        case
            when claim_date > policy_end_date then 1 --this means the claim happened after the policy ended.
            else 0
        end as claim_after_policy_end_flag,

        case
            when total_paid_premium = 0 and paid_amount > 0 then 1 --This means the company paid a claim but did not collect premium.
            else 0
        end as claim_without_premium_flag,

        case
            when paid_amount > 25000 then 1
            else 0
        end as high_severity_claim_flag

    from claims_joined

)

select *
from final