select
    adjustment_id,
    claim_id,
    adjustment_date,
    adjustment_reason,
    original_amount,
    adjusted_amount,
    adjustment_status
from {{ source('insurance_raw', 'RAW_CLAIM_ADJUSTMENTS') }}