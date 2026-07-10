select
    policy_id,
    customer_id,
    agent_id,
    policy_type,
    policy_start_date,
    policy_end_date,
    policy_status,
    region,
    annual_premium
from {{ source('insurance_raw', 'RAW_POLICIES') }}