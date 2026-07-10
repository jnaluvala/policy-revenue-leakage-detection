select
    premium_id,
    policy_id,
    payment_date,
    premium_amount,
    payment_status,
    payment_method
from {{ source('insurance_raw', 'RAW_PREMIUMS') }}