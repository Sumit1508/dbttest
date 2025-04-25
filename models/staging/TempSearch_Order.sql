{{
    config(
        materialized="table",
        alias="TempSearch_Order",
        pre_hook=["TRUNCATE TABLE {{ this }}"],
    )
}}

with
    fee_info as (
        select
            packageid as package_req_id,
            sum(doc_fee) as doc_fee,
            sum(statutory_fee) as statutory_fee,
            sum(addl_year_fee) as addl_year_fee,
            sum(copies) as copies
        from dev.accel_bi_stg.stg_serch_dim
        group by packageid
    ),

    adj_trigger_reason as (
        select
            search_id,
            reason,
            row_number() over (
                partition by search_id order by adj_process_detail_id desc
            ) as rn
        from {{ source("ACCEL_ABCNEW_RAW", "ADJ_PROCESS_DETAIL") }}
        where adj_value is not null
    ),

    canned_note as (
        select note_id, note_description
        from {{ source("ACCEL_ABCNEW_RAW", "Auto_Notes") }}
    ),

    ab_end_date as (
        select package_req_id, return_datetime
        from {{ source("ACCEL_ABCNEW_RAW", "SEARCH") }}
        where search_type_code = '9PK'
    ),

    complete_date as (
        select h.search_id, h.history_time
        from
            (
                select *
                from {{ source("ACCEL_ABCNEW_RAW", "HISTORY_DETAIL") }}
                where nullif(adj_id, '') is not null
            ) h
        join
            (
                select *
                from {{ source("ACCEL_ABCNEW_RAW", "ADJ_OPTION") }}
                where nullif(trim(adj_id), '') is not null and adj_category in (0, 1)
            ) o2
            on try_to_number(h.adj_id) = try_to_number(o2.adj_id)
        where h.status_code = 'R' and h.history_category = 'ADJ'
    ),

    package_completed as (
        select
            h.search_id,
            h.history_time as invitationemailsent,
            case
                when datediff(day, h.history_time, s.orderdate) <= 10 then 'Y' else 'N'
            end as packagecompleted10days
        from {{ source("ACCEL_ABCNEW_RAW", "HISTORY_DETAIL") }} h
        join {{ ref("Stg_Serch_Dim") }} s on s.searchid = h.search_id
        where h.history_category = 'EML'
    ),

    final_adj as (
        select
            h.search_id,
            u.user_first_name || ' ' || u.user_last_name as finaladjudicatorname
        from
            (
                select
                    search_id,
                    user_id,
                    row_number() over (
                        partition by search_id order by history_id desc
                    ) as rn
                from {{ source("ACCEL_ABCNEW_RAW", "HISTORY_DETAIL") }} h
                join
                    {{ source("ACCEL_ABCNEW_RAW", "ADJ_OPTION") }} o2
                    on try_to_number(o2.adj_id) = try_to_number(h.adj_id)
                    and o2.adj_category in (0, 1)
                where h.status_code = 'R' and h.history_category = 'ADJ'
            ) h
        join {{ source("ACCEL_ABCNEW_RAW", "ABCUSER") }} u on u.user_id = h.user_id
        where h.rn = 1
    ),

    needs_review_adj as (
        select
            h.search_id,
            u.user_first_name || ' ' || u.user_last_name as needsreviewadjudicatorname
        from
            (
                select
                    search_id,
                    user_id,
                    row_number() over (
                        partition by search_id order by history_id desc
                    ) as rn
                from {{ source("ACCEL_ABCNEW_RAW", "HISTORY_DETAIL") }} h
                join
                    {{ source("ACCEL_ABCNEW_RAW", "ADJ_OPTION") }} o2
                    on try_to_number(o2.adj_id) = try_to_number(h.adj_id)
                    and o2.adj_category = 2
                where h.status_code = 'R' and h.history_category = 'ADJ'
            ) h
        join {{ source("ACCEL_ABCNEW_RAW", "ABCUSER") }} u on u.user_id = h.user_id
        where h.rn = 1
    )

select
    so.packageid,
    so.statuscode,
    so.substatus,
    so.invoicedatetime,
    so.notmonthlyinvoicedatetime,
    so.researchersummarydate,
    so.resultnote,
    so.statusnote,
    so.email_sent,
    so.need_review_email_sent,
    so.oin_email_sent,
    so.pkg_processed,
    so.adj_id,
    so.completiondate,
    so.orderdate,
    f.doc_fee,
    f.statutory_fee,
    f.addl_year_fee as additional_year_fee,
    f.copies,
    so.refnumber2,
    so.refnumber3,
    so.refnumber4,
    so.refnumber5,
    so.orderdate as abstartdate,
    ae.return_datetime as abenddate,
    cd.history_time as completedate,
    so.searchid,
    cn.note_description as cannednote,
    atr.reason as adjtriggerreason,
    'N' as packagecompleted10days,
    0 as pastduesearchcount,
    fa.finaladjudicatorname as finaladjudicatorname,
    null as adjudicationnote,
    nra.needsreviewadjudicatorname as needsreviewadjudicatorname,
    pc.invitationemailsent as invitationemailsent,
    null as packageprocessed,
    null as dateplacedintoneedreview,
    null as adjgridid,
    null as adjgridname
from {{ ref("Stg_Serch_Dim") }} so
left join fee_info f on f.package_req_id = so.packageid
left join adj_trigger_reason atr on atr.search_id = so.searchid and atr.rn = 1
left join canned_note cn on cn.note_id = so.search_note_id
left join ab_end_date ae on ae.package_req_id = so.packageid
left join complete_date cd on cd.search_id = so.searchid
left join package_completed pc on pc.search_id = so.searchid
left join final_adj fa on fa.search_id = so.searchid
left join needs_review_adj nra on nra.search_id = so.searchid
where so.searchtypecode = '9PK'
