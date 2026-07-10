with leakage_flags as (

    select *
    from {{ ref('int_claim_leakage_flags') }}

),

claim_adjustments as (

    select *
    from {{ ref('stg_claim_adjustments') }}

),

adjustment_summary as (

    select
        claim_id,
        count(*) as adjustment_count,
        sum(adjusted_amount - original_amount) as total_adjustment_delta,
        sum(case when adjustment_status = 'Approved' then 1 else 0 end) as approved_adjustment_count,
        sum(case when adjustment_status = 'Pending' then 1 else 0 end) as pending_adjustment_count,
        sum(case when adjustment_status = 'Rejected' then 1 else 0 end) as rejected_adjustment_count

    from claim_adjustments
    group by claim_id

),

final as (

    select
        lf.claim_id,
        lf.policy_id,
        lf.customer_id,
        lf.agent_id,
        lf.policy_type,
        lf.region,
        lf.policy_start_date,
        lf.policy_end_date,

        lf.claim_date,
        lf.claim_type,
        lf.claim_status,
        lf.claim_amount,
        lf.paid_amount,
        lf.claim_severity_level,

        lf.total_paid_premium,
        lf.possible_duplicate_count,

        lf.duplicate_claim_flag,
        lf.claim_after_policy_end_flag,
        lf.claim_without_premium_flag,
        lf.high_severity_claim_flag,

        coalesce(adj.adjustment_count, 0) as adjustment_count,
        coalesce(adj.total_adjustment_delta, 0) as total_adjustment_delta,
        coalesce(adj.approved_adjustment_count, 0) as approved_adjustment_count,
        coalesce(adj.pending_adjustment_count, 0) as pending_adjustment_count,
        coalesce(adj.rejected_adjustment_count, 0) as rejected_adjustment_count,

        (
            lf.duplicate_claim_flag * 25
            + lf.claim_after_policy_end_flag * 25
            + lf.claim_without_premium_flag * 25
            + lf.high_severity_claim_flag * 10
            + case when coalesce(adj.adjustment_count, 0) > 0 then 10 else 0 end
            + case when coalesce(adj.total_adjustment_delta, 0) > 5000 then 5 else 0 end
        ) as leakage_risk_score,

        current_timestamp() as mart_created_at

    from leakage_flags lf

    left join adjustment_summary adj
        on lf.claim_id = adj.claim_id

)

select *
from final