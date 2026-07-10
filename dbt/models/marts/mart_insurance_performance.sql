with policies as (

    select *
    from {{ ref('stg_policies') }}

),

customers as (

    select *
    from {{ ref('stg_customers') }}

),

agents as (

    select *
    from {{ ref('stg_agents') }}

),

premium_summary as (

    select *
    from {{ ref('int_policy_premium_summary') }}

),

claim_summary as (

    select *
    from {{ ref('int_policy_claim_summary') }}

),

final as (

    select
        p.policy_id,
        p.customer_id,
        c.customer_name,
        c.gender,
        c.age,
        c.state as customer_state,
        c.customer_segment,

        p.agent_id,
        a.agent_name,
        a.agent_tier,

        p.policy_type,
        p.policy_status,
        p.region,
        p.policy_start_date,
        p.policy_end_date,
        p.annual_premium,

        coalesce(ps.total_paid_premium, 0) as total_paid_premium,
        coalesce(ps.total_billed_premium, 0) as total_billed_premium,
        coalesce(ps.premium_payment_count, 0) as premium_payment_count,
        coalesce(ps.problem_payment_count, 0) as problem_payment_count,

        coalesce(cs.claim_count, 0) as claim_count,
        coalesce(cs.total_claim_amount, 0) as total_claim_amount,
        coalesce(cs.total_paid_claim_amount, 0) as total_paid_claim_amount,
        coalesce(cs.avg_paid_claim_amount, 0) as avg_paid_claim_amount,
        coalesce(cs.max_paid_claim_amount, 0) as max_paid_claim_amount,

        case
            when coalesce(ps.total_paid_premium, 0) = 0 then null
            else coalesce(cs.total_paid_claim_amount, 0) / ps.total_paid_premium
        end as loss_ratio,

        case
            when coalesce(cs.claim_count, 0) = 0 then 0
            else coalesce(cs.total_paid_claim_amount, 0) / cs.claim_count
        end as claim_severity,

        case
            when coalesce(cs.claim_count, 0) > 0 then 1
            else 0
        end as has_claim,

        case
            when coalesce(ps.problem_payment_count, 0) > 0 then 1
            else 0
        end as has_payment_issue,

        current_timestamp() as mart_created_at

    from policies p

    left join customers c
        on p.customer_id = c.customer_id

    left join agents a
        on p.agent_id = a.agent_id

    left join premium_summary ps
        on p.policy_id = ps.policy_id

    left join claim_summary cs
        on p.policy_id = cs.policy_id

)

select *
from final