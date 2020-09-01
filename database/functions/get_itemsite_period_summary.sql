-- File:        get_itemsite_period_summary.sql
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
-- Provides an alternative formulation of itemsite level period ending inventory
-- reporting as compared to the persisted summary table version.
--

CREATE OR REPLACE FUNCTION
    museinvanalysis.get_itemsite_period_summary(pAsOfDate         date    DEFAULT now()::date,
                                                pItemId           integer DEFAULT NULL,
                                                pWarehousId       integer DEFAULT NULL,
                                                pIncludeAllDetail boolean DEFAULT FALSE)
    RETURNS TABLE
        ( itemsite_id         integer
         ,item_id             integer
         ,warehous_id         integer
         ,period_id           integer
         ,period_name         text
         ,period_start        date
         ,period_end          date
         ,itemsite_qtyonhand  numeric
         ,period_ending_qoh   numeric
         ,period_ending_value numeric
         ,transaction_count   bigint
         ,period_recency      bigint)
    AS
        $BODY$
            SELECT *
            FROM
                (SELECT
                     pervals.*
                    ,row_number() OVER (PARTITION BY itemsite_id ORDER BY period_end DESC) AS period_recency
                 FROM
                    (SELECT
                         its.itemsite_id
                        ,its.itemsite_item_id AS item_id
                        ,its.itemsite_warehous_id AS warehous_id
                        ,p.period_id
                        ,p.period_name
                        ,p.period_start
                        ,p.period_end
                        ,its.itemsite_qtyonhand
                        ,sum(coalesce(tdata.period_qty_movement, 0.0)) OVER
                            (PARTITION BY its.itemsite_id ORDER BY its.itemsite_id, p.period_end) AS period_ending_qoh
                        ,sum(coalesce(tdata.period_value_movement, 0.0)) OVER
                            (PARTITION BY its.itemsite_id ORDER BY its.itemsite_id, p.period_end) AS period_ending_value
                        ,coalesce(tdata.invhist_records, 0) AS transaction_count
                    FROM period p
                        CROSS JOIN itemsite its
                        LEFT OUTER JOIN (SELECT
                                             period_id
                                            ,itemsite_id
                                            ,count(invhist_id) AS invhist_records
                                            ,sum(coalesce(invhist_qoh_after, 0.0) - coalesce(invhist_qoh_before, 0)) AS period_qty_movement
                                            ,sum(coalesce(invhist_value_after, 0.0) - coalesce(invhist_value_before, 0)) AS period_value_movement
                                        FROM invhist
                                            JOIN itemsite
                                                ON invhist_itemsite_id = itemsite_id
                                            JOIN period
                                                ON invhist_transdate::date BETWEEN period_start AND period_end
                                                    AND invhist_posted
                                        WHERE
                                            period_start < pAsOfDate AND
                                            itemsite_item_id = coalesce(pItemId, itemsite_item_id) AND
                                            itemsite_warehous_id = coalesce(pWarehousId, itemsite_warehous_id)
                                        GROUP BY
                                             itemsite_id
                                            ,period_id) tdata
                            ON p.period_id = tdata.period_id AND
                                its.itemsite_id = tdata.itemsite_id
                    WHERE
                        period_start < pAsOfDate AND
                        itemsite_item_id = coalesce(pItemId, itemsite_item_id) AND
                        itemsite_warehous_id = coalesce(pWarehousId, itemsite_warehous_id)) pervals) final
            WHERE pIncludeAllDetail OR period_recency = 1;
        $BODY$
    LANGUAGE sql STABLE;

ALTER FUNCTION
    museinvanalysis.get_itemsite_period_summary( pAsOfDate         date
                                                ,pItemId           integer
                                                ,pWarehousId       integer
                                                ,pIncludeAllDetail boolean)
    OWNER TO admin;

REVOKE EXECUTE ON FUNCTION
    museinvanalysis.get_itemsite_period_summary( pAsOfDate         date
                                                ,pItemId           integer
                                                ,pWarehousId       integer
                                                ,pIncludeAllDetail boolean) FROM public;

GRANT EXECUTE ON FUNCTION
    museinvanalysis.get_itemsite_period_summary( pAsOfDate         date
                                                ,pItemId           integer
                                                ,pWarehousId       integer
                                                ,pIncludeAllDetail boolean) TO admin;
GRANT EXECUTE ON FUNCTION
    museinvanalysis.get_itemsite_period_summary( pAsOfDate         date
                                                ,pItemId           integer
                                                ,pWarehousId       integer
                                                ,pIncludeAllDetail boolean) TO xtrole;


COMMENT ON FUNCTION
    museinvanalysis.get_itemsite_period_summary( pAsOfDate         date
                                                ,pItemId           integer
                                                ,pWarehousId       integer
                                                ,pIncludeAllDetail boolean)
    IS
$DOC$Provides an alternative formulation of itemsite level period ending inventory
reporting as compared to the persisted summary table version.$DOC$;
