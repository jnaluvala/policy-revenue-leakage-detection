select
    agent_id,
    agent_name,
    state,
    region,
    hire_date,
    agent_tier
from {{ source('insurance_raw', 'RAW_AGENTS') }}