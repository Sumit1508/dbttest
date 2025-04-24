{{ config(
    materialized='incremental',
    unique_key='SearchId',
    post_hook=[
        "INSERT INTO ACCEL_LOGGINGDB.load_audit_log (model_name, last_run_timestamp) 
        SELECT 'Stg_Search_Dim', MAX(last_update_date)
        FROM {{ this }}"
    ]
) }}


WITH last_run AS (
    SELECT MAX(last_run_timestamp) AS last_run
    FROM ACCEL_LOGGINGDB.load_audit_log
    WHERE model_name = 'Stg_Serch_Dim'
),

GetDeltaSearch_SearchId AS (
    SELECT DISTINCT s1.search_id
    FROM ACCEL_ABCNEW_RAW.SEARCH s1
    WHERE (
        s1.package_req_id IN (
            SELECT s.package_req_id
            FROM ACCEL_ABCNEW_RAW.SEARCH s
            WHERE s.last_update_date >= (SELECT last_run FROM last_run)
        )
        OR (s1.last_update_date >= (SELECT last_run FROM last_run) AND s1.package_req_id IS NULL)
    )
),

LatestFollowUpNote AS (
    SELECT searchId, followUpNote
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY searchId ORDER BY id DESC) AS rn
        FROM ACCEL_ABCNEW_RAW.FOLLOW_UP_HISTORY
    )
    WHERE rn = 1
)

SELECT
    s.search_id AS SearchId,
    s.package_req_id AS PackageId,
    s.order_datetime AS OrderDate,
    LEFT(s.client_ref_number, 50) AS ClientRefNum,
    LEFT(s.ref_number2, 50) AS RefNumber2,
    LEFT(s.ref_number3, 50) AS RefNumber3,
    LEFT(s.ref_number4, 50) AS RefNumber4,
    LEFT(s.ref_number5, 80) AS RefNumber5,
    s.return_datetime AS CompletionDate,
    s.search_type_code AS SearchTypeCode,
    s.invoice_datetime AS InvoiceDatetime,
    s.not_monthly_invoice_datetime AS NotMonthlyInvoiceDatetime,
    s.researcher_summary_date AS ResearcherSummaryDate,
    s.copies,
    CAST(s.result_note AS STRING) AS ResultNote,
    s.status_note AS StatusNote,
    s.email_sent,
    s.need_review_email_sent,
    s.oin_email_sent,
    s.pkg_processed,
    s.ala_carte,
    s.t_and_c,
    s.reason_added,
    st.status AS Status,
    s.sub_status AS SubStatus,
    CAST(s.state_code AS STRING) AS State,
    c.county_name AS County,
    s.requestor_id AS RequestorId,
    s.pkg_code AS PackageCode,
    s.search_status AS StatusCode,
    s.last_update_date,
    COALESCE(sc.state_name, CAST(s.state_code AS STRING)) AS State_Name,
    s.search_note_id,
    s.DOC_FEE,
    s.STATUTORY_FEE,
    s.addl_year_fee,
    s.adj_id,
    s.request_print_datetime,
    CAST(ct.country_code AS STRING) AS Country_Code,
    CAST(ct.country_name AS STRING) AS Country_Name,
    s.researcher_id,
    c.county_id,
    s.result_print_datetime,
    s.year_searched,
    CAST(n.note_description AS STRING) AS note_description,

    CASE 
        WHEN TRY_TO_DATE(SUBSTR(fh.followUpNote, CHARINDEX(']', fh.followUpNote) + 2, 10)) IS NOT NULL THEN 
            TO_DATE(SUBSTR(fh.followUpNote, CHARINDEX(']', fh.followUpNote) + 2, 10))
        WHEN fh.followUpNote ILIKE '%;TAT 10%' THEN NULL
        ELSE NULL
    END AS VendorETADate

FROM ACCEL_ABCNEW_RAW.SEARCH s
LEFT JOIN GetDeltaSearch_SearchId g ON s.search_id = g.search_id
LEFT JOIN ACCEL_ABCNEW_RAW.COUNTY c ON c.county_id = s.county_id
LEFT JOIN ACCEL_ABCNEW_RAW.COUNTRY ct ON ct.country_code = c.country_code
LEFT JOIN ACCEL_ABCNEW_RAW.SEARCH_STATUS st ON st.status_code = s.search_status
LEFT JOIN ACCEL_ABCNEW_RAW.STATE_CODE sc ON sc.state_code = s.state_code
LEFT JOIN ACCEL_ABCNEW_RAW.Auto_Notes n ON n.note_id = s.search_note_id
LEFT JOIN LatestFollowUpNote fh ON fh.searchId = s.search_id

{% if is_incremental() %}
WHERE s.last_update_date > (SELECT last_run FROM last_run)
{% endif %}
