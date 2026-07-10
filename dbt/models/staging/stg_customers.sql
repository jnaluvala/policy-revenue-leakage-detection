select
    customer_id,
    customer_name,
    gender,
    age,
    state,
    region,
    customer_segment,
    created_date
from {{ source('insurance_raw', 'RAW_CUSTOMERS') }}