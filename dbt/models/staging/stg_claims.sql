select
    claim_id,
    policy_id,
    claim_date,
    claim_type,
    claim_status,
    claim_amount,
    paid_amount,
    claim_severity_level
from {{ source('insurance_raw', 'RAW_CLAIMS') }}