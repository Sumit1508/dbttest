WITH fee_info AS (
    SELECT 
        PackageId AS package_req_id,
        SUM(DOC_FEE) AS DOC_FEE,
        SUM(STATUTORY_FEE) AS STATUTORY_FEE,
        SUM(addl_year_fee) AS addl_year_fee,
        SUM(COPIES) AS COPIES
    FROM {{ ref('Stg_Serch_Dim') }}
    GROUP BY PackageId
),
adj_trigger_reason AS (
    SELECT 
        search_id,
        reason,
        ROW_NUMBER() OVER (PARTITION BY search_id ORDER BY adj_process_detail_id DESC) AS rw
    FROM {{ source('ACCEL_ABCNEW_RAW', 'ADJ_PROCESS_DETAIL') }}
    WHERE adj_value IS NOT NULL
),
canned_note AS (
    SELECT 
        search_note_id,
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
        search_id,
        history_time
    FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }}
    WHERE status_Code = 'R'
      AND history_category = 'ADJ'
      AND EXISTS (
          SELECT 1 FROM {{ source('ACCEL_ABCNEW_RAW', 'ADJ_OPTION') }} o2
          WHERE o2.adj_id = h.adj_id AND o2.adj_category IN (0, 1)
      )
),
package_completed AS (
    SELECT 
        h.search_id,
        CASE 
            WHEN DATEDIFF(DAY, h.history_time, s.OrderDate) <= 10 THEN 'Y'
            ELSE 'N'
        END AS PackageCompleted10Days,
        h.history_time AS InvitationEmailSent
    FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }} h
    INNER JOIN {{ ref('Stg_Serch_Dim') }} s ON s.SearchId = h.search_id
    WHERE h.history_id = (
        SELECT MIN(h5.history_id)
        FROM {{ ref('Stg_Serch_Dim') }} CE
        CROSS APPLY {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }} h5
        WHERE h5.search_id = h.search_id
        AND h5.history_category = 'EML' 
        AND h5.history LIKE CE.convention
    )
),
adjudicator_info AS (
    SELECT 
        h.search_id, 
        A.user_first_name || ' ' || A.user_last_name AS FinalAdjudicatorName,
        AU.user_first_name || ' ' || AU.user_last_name AS NeedsReviewAdjudicatorName,
        adj_adjudicator_review_note
    FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }} h
    LEFT JOIN {{ source('ACCEL_ABCNEW_RAW', 'ABCUSER') }} A ON A.user_id = h.user_id
    LEFT JOIN {{ source('ACCEL_ABCNEW_RAW', 'ABCUSER') }} AU ON AU.user_id = h.user_id
    WHERE h.history_id = (
        SELECT MAX(h5.history_id)
        FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }} h5
        INNER JOIN {{ source('ACCEL_ABCNEW_RAW', 'ADJ_OPTION') }} o2 ON o2.adj_id = h5.adj_id
        WHERE h5.search_id = h.search_id AND h5.status_Code = 'R'
        AND h5.history_category = 'ADJ' AND o2.adj_category IN (0, 1)
    )
)

-- Main query starts here
SELECT 
    SO.SearchId,
    COALESCE(SO.PackageId, F.PackageId) AS PackageId,
    COALESCE(SO.StatusCode, F.StatusCode) AS StatusCode,
    -- Add other fields like in your original query
    COALESCE(F.DOC_FEE, 0) AS DOC_FEE,
    COALESCE(F.STATUTORY_FEE, 0) AS STATUTORY_FEE,
    COALESCE(F.ADDITIONAL_YEAR_FEE, 0) AS ADDITIONAL_YEAR_FEE,
    -- Additional fields
    COALESCE(AI.FinalAdjudicatorName, 'N/A') AS FinalAdjudicatorName
FROM 
    {{ ref('TempSearch_Order') }} SO
LEFT JOIN fee_info F ON F.package_req_id = SO.PackageId
LEFT JOIN adj_trigger_reason ATR ON ATR.search_id = SO.SearchId AND ATR.rw = 1
LEFT JOIN canned_note CN ON CN.search_note_id = SO.search_note_id
LEFT JOIN ab_end_date AE ON AE.package_req_id = SO.PackageId
LEFT JOIN complete_date CD ON CD.search_id = SO.SearchId
LEFT JOIN package_completed PC ON PC.search_id = SO.SearchId
LEFT JOIN adjudicator_info AI ON AI.search_id = SO.SearchId

{% if is_incremental() %}
    -- Add incremental logic to update existing records
    WHERE SO.SearchId NOT IN (SELECT SearchId FROM {{ this }})
{% endif %}
