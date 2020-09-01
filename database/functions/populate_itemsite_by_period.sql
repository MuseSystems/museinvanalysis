-- File:        populate_itemsite_by_period.sql
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
-- Truncates and repopulates the itemsite level data from the transaction
-- history data.
--

CREATE OR REPLACE FUNCTION museinvanalysis.populate_itemsite_by_period()
    RETURNS void AS
        $BODY$

            TRUNCATE TABLE museinvanalysis.itemsite_by_period;

            INSERT INTO museinvanalysis.itemsite_by_period
                (itemsite_by_period_period_id
                ,itemsite_by_period_itemsite_id
                ,itemsite_by_period_yearperiod_id
                ,itemsite_by_period_qty_in
                ,itemsite_by_period_value_in
                ,itemsite_by_period_qty_out
                ,itemsite_by_period_value_out
                ,itemsite_by_period_ending_qoh
                ,itemsite_by_period_ending_value
                ,itemsite_by_period_ending_unitcost)
            SELECT
                 itemsite_periods_period_id
                ,itemsite_periods_itemsite_id
                ,itemsite_periods_yearperiod_id
                ,period_qty_in
                ,period_value_in
                ,period_qty_out
                ,period_value_out
                ,period_ending_qoh
                ,period_ending_value
                ,CASE
                    WHEN period_ending_qoh <> 0.0 THEN
                        period_ending_value / period_ending_qoh
                    ELSE
                        0.00
                 END AS period_ending_unitcost
            FROM
                (SELECT
                     ip.itemsite_periods_period_id
                    ,ip.itemsite_periods_itemsite_id
                    ,ip.itemsite_periods_yearperiod_id
                    ,coalesce(tdata.period_qty_in, 0.0) AS period_qty_in
                    ,coalesce(tdata.period_value_in, 0.0) AS period_value_in
                    ,coalesce(tdata.period_qty_out, 0.0) AS period_qty_out
                    ,coalesce(tdata.period_value_out, 0.0) AS period_value_out
                    ,sum(coalesce(tdata.period_qty_movement, 0.0)) OVER
                        (PARTITION BY ip.itemsite_periods_itemsite_id
                            ORDER BY ip.itemsite_periods_itemsite_id, ip.itemsite_periods_period_end) AS period_ending_qoh
                    ,sum(coalesce(tdata.period_value_movement, 0.0)) OVER
                        (PARTITION BY ip.itemsite_periods_itemsite_id
                            ORDER BY ip.itemsite_periods_itemsite_id, ip.itemsite_periods_period_end) AS period_ending_value
                FROM museinvanalysis.itemsite_periods ip
                    LEFT OUTER JOIN (SELECT
                                         period_id
                                        ,invhist_itemsite_id AS itemsite_id
                                        ,sum(CASE
                                                WHEN coalesce(invhist_qoh_after, 0.0) - coalesce(invhist_qoh_before, 0) > 0 THEN
                                                    coalesce(invhist_qoh_after, 0.0) - coalesce(invhist_qoh_before, 0)
                                                ELSE
                                                    0.0
                                             END) AS period_qty_in
                                        ,sum(CASE
                                                WHEN coalesce(invhist_qoh_after, 0.0) - coalesce(invhist_qoh_before, 0) < 0 THEN
                                                    coalesce(invhist_qoh_after, 0.0) - coalesce(invhist_qoh_before, 0)
                                                ELSE
                                                    0.0
                                             END) AS period_qty_out
                                        ,sum(CASE
                                                WHEN coalesce(invhist_value_after, 0.0) - coalesce(invhist_value_before, 0) > 0 THEN
                                                    coalesce(invhist_value_after, 0.0) - coalesce(invhist_value_before, 0)
                                                ELSE
                                                    0.0
                                             END) AS period_value_in
                                        ,sum(CASE
                                                WHEN coalesce(invhist_value_after, 0.0) - coalesce(invhist_value_before, 0) < 0 THEN
                                                    coalesce(invhist_value_after, 0.0) - coalesce(invhist_value_before, 0)
                                                ELSE
                                                    0.0
                                             END) AS period_value_out
                                        ,sum(coalesce(invhist_qoh_after, 0.0) - coalesce(invhist_qoh_before, 0)) AS period_qty_movement
                                        ,sum(coalesce(invhist_value_after, 0.0) - coalesce(invhist_value_before, 0)) AS period_value_movement
                                    FROM invhist
                                        JOIN period
                                            ON invhist_transdate::date BETWEEN period_start AND period_end
                                    WHERE invhist_posted
                                    GROUP BY
                                         period_id
                                        ,invhist_itemsite_id) tdata
                        ON tdata.period_id = ip.itemsite_periods_period_id AND
                            ip.itemsite_periods_itemsite_id = tdata.itemsite_id) pf
            ORDER BY itemsite_periods_period_id, itemsite_periods_itemsite_id;

        $BODY$
    LANGUAGE sql VOLATILE;

ALTER FUNCTION museinvanalysis.populate_itemsite_by_period()
    OWNER TO admin;

REVOKE EXECUTE ON FUNCTION museinvanalysis.populate_itemsite_by_period() FROM public;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_itemsite_by_period() TO admin;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_itemsite_by_period() TO xtrole;


COMMENT ON FUNCTION museinvanalysis.populate_itemsite_by_period()
    IS $DOC$Truncates and repopulates the itemsite level data from the transaction history data.$DOC$;
