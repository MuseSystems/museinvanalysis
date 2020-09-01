-- File:        get_invdetail_period_summary.sql
-- Location:    /home/scb/Dropbox/muse/src/products/xtuple/museinvanalysis/database/functions
-- Project:     Muse Systems Inventory Analysis for xTuple ERP
--
-- Licensed to Lima Buttgereit Holdings LLC (d/b/a Muse Systems) under one or
-- more agreements.  Muse Systems licenses this file to you under the Apache
-- License, Version 2.0.
--
-- See the LICENSE file in the project root for license terms and conditions.
-- See the NOTICE file in the project root for copyright ownership information.
--
-- muse.information@musesystems.com  :: https://muse.systems

--
-- An alternative, realtime formulation of period ending inventory for
-- location/lot/serial controlled inventory.  Note that as it currently exists,
-- this function only reports at the Lot/Serial level, summing all locations.
--

CREATE OR REPLACE FUNCTION
    museinvanalysis.get_invdetail_period_summary(pAsOfDate         date    DEFAULT now()::date
                                                ,pItemId           integer DEFAULT NULL
                                                ,pWarehousId       integer DEFAULT NULL
                                                ,pIncludeAllDetail boolean DEFAULT FALSE)
    RETURNS TABLE
        ( itemsite_id                  integer
         ,item_id                      integer
         ,warehous_id                  integer
         ,ls_id                        integer
         ,period_id                    integer
         ,period_name                  text
         ,period_start                 date
         ,period_end                   date
         ,itemsite_qtyonhand           numeric
         ,itemsite_value               numeric
         ,period_total_ending_qoh      numeric
         ,period_total_ending_value    numeric
         ,detail_ending_qoh            numeric
         ,detail_ending_value          numeric
         ,calc_period_ending_unit_cost numeric
         ,period_recency               bigint)
    AS
        $BODY$
            SELECT *
            FROM
                (SELECT
                     itemsite_id
                    ,item_id
                    ,warehous_id
                    ,ls_id
                    ,period_id
                    ,period_name
                    ,period_start
                    ,period_end
                    ,itemsite_qtyonhand
                    ,itemsite_value
                    ,period_total_ending_qoh
                    ,period_total_ending_value
                    ,detail_ending_qoh
                    ,CASE
                        WHEN period_total_ending_qoh <> 0 THEN
                            ROUND(detail_ending_qoh * (period_total_ending_value / period_total_ending_qoh), 2)
                        ELSE
                            0.00
                     END AS detail_ending_value
                    ,CASE
                        WHEN period_total_ending_qoh <> 0 THEN
                            ROUND(period_total_ending_value / period_total_ending_qoh, 2)
                        ELSE
                            0.00
                     END AS calc_period_ending_unit_cost
                    ,row_number() OVER (PARTITION BY itemsite_id, ls_id ORDER BY period_end DESC) AS period_recency
                 FROM
                    (SELECT
                         targ.itemsite_id AS itemsite_id
                        ,targ.itemsite_item_id AS item_id
                        ,targ.itemsite_warehous_id AS warehous_id
                        ,targ.ls_id AS ls_id
                        ,targ.period_id
                        ,targ.period_name
                        ,targ.period_start
                        ,targ.period_end
                        ,targ.itemsite_qtyonhand
                        ,targ.itemsite_value
                        ,SUM(COALESCE(totals.total_qty_movement, 0.0)) OVER
                            (PARTITION BY targ.itemsite_id, targ.ls_id ORDER BY targ.period_end) AS period_total_ending_qoh
                        ,SUM(COALESCE(totals.total_value_movement, 0.0)) OVER
                            (PARTITION BY targ.itemsite_id, targ.ls_id ORDER BY targ.period_end) AS period_total_ending_value
                        ,SUM(COALESCE(details.detail_qty_movement, 0.0)) OVER
                            (PARTITION BY targ.itemsite_id, targ.ls_id ORDER BY targ.period_end) AS detail_ending_qoh
                    FROM (SELECT DISTINCT
                             period_id
                            ,period_name
                            ,period_start
                            ,period_end
                            ,itemsite_id
                            ,itemsite_item_id
                            ,itemsite_warehous_id
                            ,itemsite_qtyonhand
                            ,itemsite_value
                            ,invdetail_ls_id AS ls_id
                            FROM period p
                                CROSS JOIN
                                    (SELECT DISTINCT
                                          itemsite_id
                                         ,itemsite_item_id
                                         ,itemsite_warehous_id
                                         ,itemsite_qtyonhand
                                         ,itemsite_value
                                         ,invdetail_ls_id
                                     FROM invhist
                                        JOIN itemsite ON invhist_itemsite_id = itemsite_id
                                        JOIN invdetail ON invhist_id = invdetail_invhist_id
                                     WHERE  invhist_posted AND
                                            itemsite_item_id = coalesce(pItemId, itemsite_item_id) AND
                                            itemsite_warehous_id = coalesce(pWarehousId, itemsite_warehous_id)) items
                            WHERE period_start < pAsOfDate) targ
                        LEFT OUTER JOIN (SELECT
                                             period_id
                                            ,itemsite_id
                                            ,itemsite_warehous_id
                                            ,invdetail_ls_id
                                            ,sum(coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0.0)) AS detail_qty_movement
                                        FROM period
                                            JOIN invhist
                                                ON invhist_transdate::date BETWEEN period_start AND period_end
                                            JOIN itemsite
                                                ON itemsite_id = invhist_itemsite_id
                                            LEFT OUTER JOIN invdetail
                                                ON invdetail_invhist_id = invhist_id
                                        WHERE  invhist_posted AND
                                                period_start < pAsOfDate AND
                                                itemsite_item_id = coalesce(pItemId, itemsite_item_id) AND
                                                itemsite_warehous_id = coalesce(pWarehousId, itemsite_warehous_id)
                                        GROUP BY period_id, itemsite_id, invdetail_ls_id) details
                            ON targ.period_id = details.period_id AND
                                targ.itemsite_id = details.itemsite_id AND
                                targ.ls_id = details.invdetail_ls_id
                        LEFT OUTER JOIN (SELECT
                                             period_id AS period_id
                                            ,itemsite_id
                                            ,sum(coalesce(invhist_value_after, 0.0) - coalesce(invhist_value_before, 0)) AS total_value_movement
                                            ,sum(coalesce(invhist_qoh_after, 0.0) - coalesce(invhist_qoh_before, 0)) AS total_qty_movement
                                         FROM invhist
                                            JOIN itemsite
                                                on invhist_itemsite_id = itemsite_id
                                            JOIN period
                                                ON invhist_transdate::date BETWEEN period_start AND period_end
                                         WHERE invhist_posted AND
                                                period_start < pAsOfDate AND
                                                itemsite_item_id = coalesce(pItemId, itemsite_item_id) AND
                                                itemsite_warehous_id = coalesce(pWarehousId, itemsite_warehous_id)
                                         GROUP BY period_id, itemsite_id) totals
                            ON targ.period_id = totals.period_id AND
                                targ.itemsite_id = totals.itemsite_id) pervals) final
            WHERE pIncludeAllDetail OR period_recency = 1;
        $BODY$
    LANGUAGE sql STABLE;

ALTER FUNCTION
    museinvanalysis.get_invdetail_period_summary( pAsOfDate         date
                                                 ,pItemId           integer
                                                 ,pWarehousId       integer
                                                 ,pIncludeAllDetail boolean)
    OWNER TO admin;

REVOKE EXECUTE ON FUNCTION
    museinvanalysis.get_invdetail_period_summary( pAsOfDate         date
                                                 ,pItemId           integer
                                                 ,pWarehousId       integer
                                                 ,pIncludeAllDetail boolean)
    FROM public;

GRANT EXECUTE ON FUNCTION
    museinvanalysis.get_invdetail_period_summary( pAsOfDate         date
                                                 ,pItemId           integer
                                                 ,pWarehousId       integer
                                                 ,pIncludeAllDetail boolean)
    TO admin;

GRANT EXECUTE ON FUNCTION
    museinvanalysis.get_invdetail_period_summary( pAsOfDate         date
                                                 ,pItemId           integer
                                                 ,pWarehousId       integer
                                                 ,pIncludeAllDetail boolean)
    TO xtrole;



COMMENT ON FUNCTION
    museinvanalysis.get_invdetail_period_summary( pAsOfDate         date
                                                 ,pItemId           integer
                                                 ,pWarehousId       integer
                                                 ,pIncludeAllDetail boolean)
    IS
$DOC$An alternative, realtime formulation of period ending inventory for
location/lot/serial controlled inventory.  Note that as it currently exists,
this function only reports at the Lot/Serial level, summing all locations. $DOC$;
