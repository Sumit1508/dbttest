{{ config(
    materialized = 'incremental',
    unique_key = 'SearchId'
) }}

WITH fee_info AS (
    SELECT 
        PackageId AS package_req_id,
        SUM(DOC_FEE) AS DOC_FEE,
        SUM(STATUTORY_FEE) AS STATUTORY_FEE,
        SUM(addl_year_fee) AS addl_year_fee,
        SUM(COPIES) AS COPIES
    FROM DEV.ACCEL_BI_STG.Stg_Serch_Dim
    GROUP BY PackageId
),

adj_trigger_reason AS (
    SELECT 
        search_id,
        reason,
        ROW_NUMBER() OVER (PARTITION BY search_id ORDER BY adj_process_detail_id DESC) AS rn
    FROM {{ source('ACCEL_ABCNEW_RAW', 'ADJ_PROCESS_DETAIL') }}
    WHERE adj_value IS NOT NULL
),

canned_note AS (
    SELECT 
        note_id,
        note_description
    FROM {{ source('ACCEL_ABCNEW_RAW', 'Auto_Notes') }}
),

ab_end_date AS (
    SELECT 
        package_req_id,
        return_datetime
    FROM {{ source('ACCEL_ABCNEW_RAW', 'SEARCH') }}
    WHERE search_type_code = '9PK'
),

complete_date AS (
SELECT 
    h.search_id,
    h.history_time
FROM (
    SELECT *
    FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }}
    WHERE NULLIF(adj_id, '') IS NOT NULL  -- Excluding empty string `adj_id` values
) h
JOIN (
SELECT *
FROM {{ source('ACCEL_ABCNEW_RAW', 'ADJ_OPTION') }}
WHERE NULLIF(TRIM(adj_id), '') IS NOT NULL 
  AND adj_category IN (0, 1)
) o2 
ON TRY_TO_NUMBER(h.adj_id) = TRY_TO_NUMBER(o2.adj_id)
WHERE h.status_code = 'R'
  AND h.history_category = 'ADJ'

),

package_completed AS (
    SELECT 
        h.search_id,
        h.history_time AS InvitationEmailSent,
        CASE 
            WHEN DATEDIFF(DAY, h.history_time, s.OrderDate) <= 10 THEN 'Y'
            ELSE 'N'
        END AS PackageCompleted10Days
    FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }} h
    JOIN {{ ref('Stg_Serch_Dim') }} s ON s.SearchId = h.search_id
    WHERE h.history_category = 'EML'
),

final_adj AS (
    SELECT 
        h.search_id,
        u.user_first_name || ' ' || u.user_last_name AS FinalAdjudicatorName
    FROM (
        SELECT 
            search_id,
            user_id,
            ROW_NUMBER() OVER (PARTITION BY search_id ORDER BY history_id DESC) AS rn
        FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }} h
        JOIN {{ source('ACCEL_ABCNEW_RAW', 'ADJ_OPTION') }} o2 
            ON TRY_TO_NUMBER(o2.adj_id) = TRY_TO_NUMBER(h.adj_id) AND o2.adj_category IN (0, 1)
        WHERE h.status_code = 'R' AND h.history_category = 'ADJ'
    ) h
    JOIN {{ source('ACCEL_ABCNEW_RAW', 'ABCUSER') }} u ON u.user_id = h.user_id
    WHERE h.rn = 1
),

needs_review_adj AS (
    SELECT 
        h.search_id,
        u.user_first_name || ' ' || u.user_last_name AS NeedsReviewAdjudicatorName
    FROM (
        SELECT 
            search_id,
            user_id,
            ROW_NUMBER() OVER (PARTITION BY search_id ORDER BY history_id DESC) AS rn
        FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }} h
        JOIN {{ source('ACCEL_ABCNEW_RAW', 'ADJ_OPTION') }} o2 
            ON TRY_TO_NUMBER(o2.adj_id) = TRY_TO_NUMBER(h.adj_id) AND o2.adj_category = 2
        WHERE h.status_code = 'R' AND h.history_category = 'ADJ'
    ) h
    JOIN {{ source('ACCEL_ABCNEW_RAW', 'ABCUSER') }} u ON u.user_id = h.user_id
    WHERE h.rn = 1
)

SELECT 
    so.*,

    -- Enriched fields

    atr.reason AS AdjTriggerReason,
    cn.note_description AS CannedNote,
    ae.return_datetime AS ABEndDate,
    cd.history_time AS CompleteDate,
    pc.PackageCompleted10Days,
    pc.InvitationEmailSent,
    fa.FinalAdjudicatorName,
    nra.NeedsReviewAdjudicatorName,
    so.AdjudicationNote

FROM {{ ref('TempSearch_Order') }} so
LEFT JOIN {{ ref('Stg_Serch_Dim') }} s ON  s.searchId=so.SearchId
LEFT JOIN fee_info f ON f.package_req_id = so.PackageId
LEFT JOIN adj_trigger_reason atr ON atr.search_id = so.SearchId AND atr.rn = 1
LEFT JOIN canned_note cn ON cn.note_id = s.search_note_id
LEFT JOIN ab_end_date ae ON ae.package_req_id = so.PackageId
LEFT JOIN complete_date cd ON cd.search_id = so.SearchId
LEFT JOIN package_completed pc ON pc.search_id = so.SearchId
LEFT JOIN final_adj fa ON fa.search_id = so.SearchId
LEFT JOIN needs_review_adj nra ON nra.search_id = so.SearchId

{% if is_incremental() %}
WHERE so.SearchId NOT IN (SELECT SearchId FROM {{ this }})
{% endif %}
