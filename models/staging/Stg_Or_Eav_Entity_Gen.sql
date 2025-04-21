SELECT 
    EAVG_Id, 
    EAVG_OR_Id, 
    EAVG_GA_Id, 
    EAVG_ET_Id, 
    EAVG_Value
FROM {{ source('ACCEL_ABCNEW_RAW', 'OR_EAV_ENTITY_GEN') }}
WHERE EAVG_GA_Id IN (56, 41, 42, 44)
