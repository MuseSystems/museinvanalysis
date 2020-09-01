-- File:        populate_invdetail_by_period.sql
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
-- Function is not yet documented.
--

CREATE OR REPLACE FUNCTION museinvanalysis.populate_invdetail_by_period()
    RETURNS void AS
        $BODY$
            TRUNCATE TABLE museinvanalysis.invdetail_by_period;

            INSERT INTO museinvanalysis.invdetail_by_period
                (invdetail_by_period_period_id
                ,invdetail_by_period_itemsite_id
                ,invdetail_by_period_location_id
                ,invdetail_by_period_ls_id
                ,invdetail_by_period_yearperiod_id
                ,invdetail_by_period_qty_in
                ,invdetail_by_period_value_in
                ,invdetail_by_period_adjust_value_in
                ,invdetail_by_period_qty_out
                ,invdetail_by_period_value_out
                ,invdetail_by_period_adjust_value_out
                ,invdetail_by_period_ending_qoh
                ,invdetail_by_period_ending_value
                ,invdetail_by_period_ending_unitcost)
            SELECT
                 detailtotal.invdetail_periods_period_id
                ,detailtotal.invdetail_periods_itemsite_id
                ,detailtotal.invdetail_periods_location_id
                ,detailtotal.invdetail_periods_ls_id
                ,detailtotal.invdetail_periods_yearperiod_id
                ,detailtotal.period_qty_in
                ,detailtotal.period_value_in
                ,CASE
                    WHEN detailtotal.period_ending_qoh <> 0.0 THEN
                        ibp.adjust_value_in / detailtotal.period_ending_qoh
                    ELSE
                        0.0
                 END AS period_adjust_value_in
                ,detailtotal.period_qty_out
                ,detailtotal.period_value_out
                ,CASE
                    WHEN detailtotal.period_ending_qoh <> 0.0 THEN
                        ibp.adjust_value_out / detailtotal.period_ending_qoh
                    ELSE
                        0.0
                 END AS period_adjust_value_out
                ,detailtotal.period_ending_qoh
                ,detailtotal.period_ending_qoh * ibp.itemsite_by_period_ending_unitcost AS period_ending_value
                ,ibp.itemsite_by_period_ending_unitcost
            FROM
                (SELECT
                     ip.invdetail_periods_period_id
                    ,ip.invdetail_periods_period_start
                    ,ip.invdetail_periods_period_end
                    ,ip.invdetail_periods_itemsite_id
                    ,ip.invdetail_periods_location_id
                    ,ip.invdetail_periods_ls_id
                    ,ip.invdetail_periods_yearperiod_id
                    ,coalesce(detail.period_qty_in, 0.0) AS period_qty_in
                    ,coalesce(detail.period_value_in, 0.00) AS period_value_in
                    ,coalesce(detail.period_qty_out, 0.0) AS period_qty_out
                    ,coalesce(detail.period_value_out, 0.00) AS period_value_out
                    ,sum(coalesce(detail.period_qty_movement, 0.0)) OVER
                        (PARTITION BY ip.invdetail_periods_itemsite_id, ip.invdetail_periods_location_id, ip.invdetail_periods_ls_id
                            ORDER BY ip.invdetail_periods_period_end) AS period_ending_qoh
                FROM museinvanalysis.invdetail_periods ip

                    LEFT OUTER JOIN (SELECT
                                         period_id
                                        ,invhist_itemsite_id AS itemsite_id
                                        ,nullif(invdetail_location_id, -1) AS location_id
                                        ,nullif(invdetail_ls_id, -1) AS ls_id
                                        ,sum(CASE
                                                WHEN coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0) > 0 THEN
                                                    coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0)
                                                ELSE
                                                    0.0
                                             END) AS period_qty_in
                                        ,sum(CASE
                                                WHEN coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0) < 0 THEN
                                                    coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0)
                                                ELSE
                                                    0.0
                                             END) AS period_qty_out
                                        ,sum(CASE
                                                WHEN coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0) > 0 THEN
                                                    coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0) *
                                                    detailtrans.trans_unitcost
                                                ELSE
                                                    0.0
                                             END) AS period_value_in
                                        ,sum(CASE
                                                WHEN coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0) < 0 THEN
                                                    coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0) *
                                                    detailtrans.trans_unitcost
                                                ELSE
                                                    0.0
                                             END) AS period_value_out
                                        ,sum(coalesce(invdetail_qty_after, 0.0) -
                                            coalesce(invdetail_qty_before, 0.0)) AS period_qty_movement
                                        ,sum(coalesce(invdetail_qty_after, 0.0) - coalesce(invdetail_qty_before, 0) *
                                             detailtrans.trans_unitcost) AS period_value_movement
                                     FROM  invdetail
                                        JOIN (  SELECT DISTINCT
                                                     invhist_id
                                                    ,invhist_itemsite_id
                                                    ,invhist_transdate::date
                                                    ,CASE
                                                        WHEN
                                                            coalesce(invhist_qoh_after, 0.0) -
                                                            coalesce(invhist_qoh_before, 0.0) <> 0.0
                                                        THEN
                                                            (coalesce(invhist_value_after, 0.0) -
                                                                coalesce(invhist_value_before, 0.0)) /
                                                            (coalesce(invhist_qoh_after, 0.0) -
                                                                coalesce(invhist_qoh_before, 0.0))
                                                        ELSE
                                                            0.0
                                                     END AS trans_unitcost
                                                 FROM invhist
                                                 WHERE invhist_posted) detailtrans
                                            ON detailtrans.invhist_id = invdetail_invhist_id
                                        JOIN period
                                            ON invhist_transdate::date
                                                BETWEEN period_start AND period_end
                                     GROUP BY
                                         period_id
                                        ,invhist_itemsite_id
                                        ,nullif(invdetail_location_id, -1)
                                        ,nullif(invdetail_ls_id, -1)) detail
                        ON detail.period_id = ip.invdetail_periods_period_id AND
                            detail.itemsite_id = ip.invdetail_periods_itemsite_id AND
                            coalesce(detail.location_id, -1) = coalesce(ip.invdetail_periods_location_id, -1) AND
                            coalesce(detail.ls_id, -1) = coalesce(ip.invdetail_periods_ls_id, -1)) detailtotal
            JOIN (  SELECT
                         itemsite_by_period_period_id
                        ,itemsite_by_period_itemsite_id
                        ,itemsite_by_period_ending_unitcost
                        ,coalesce(adjust_value_in, 0.0) AS adjust_value_in
                        ,coalesce(adjust_value_out, 0.0) AS adjust_value_out
                    FROM museinvanalysis.itemsite_by_period
                        LEFT OUTER JOIN (SELECT
                                             period_id
                                            ,invhist_itemsite_id
                                            ,sum(CASE
                                                    WHEN
                                                        coalesce(invhist_value_after, 0.0) -
                                                        coalesce(invhist_value_before, 0.0) > 0.0
                                                    THEN
                                                        coalesce(invhist_value_after, 0.0) -
                                                        coalesce(invhist_value_before, 0.0)
                                                END) AS adjust_value_in
                                            ,sum(CASE
                                                    WHEN
                                                        coalesce(invhist_value_after, 0.0) -
                                                        coalesce(invhist_value_before, 0.0) < 0.0
                                                    THEN
                                                        coalesce(invhist_value_after, 0.0) -
                                                        coalesce(invhist_value_before, 0.0)
                                                END) AS adjust_value_out
                                         FROM invhist
                                            JOIN period
                                                ON invhist_transdate::date BETWEEN period_start AND period_end
                                            LEFT OUTER JOIN invdetail
                                                ON invhist_id = invdetail_invhist_id
                                         WHERE invhist_posted AND invdetail_id IS NULL
                                         GROUP BY period_id, invhist_itemsite_id) adjust
                            ON invhist_itemsite_id = itemsite_by_period_itemsite_id AND
                                period_id = itemsite_by_period_period_id) ibp
                ON detailtotal.invdetail_periods_period_id = ibp.itemsite_by_period_period_id AND
                    detailtotal.invdetail_periods_itemsite_id = ibp.itemsite_by_period_itemsite_id
            ORDER BY
                detailtotal.invdetail_periods_period_end,
                detailtotal.invdetail_periods_itemsite_id,
                detailtotal.invdetail_periods_location_id,
                detailtotal.invdetail_periods_ls_id ;


        $BODY$
    LANGUAGE sql VOLATILE;

ALTER FUNCTION museinvanalysis.populate_invdetail_by_period()
    OWNER TO admin;

REVOKE EXECUTE ON FUNCTION museinvanalysis.populate_invdetail_by_period() FROM public;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_invdetail_by_period() TO admin;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_invdetail_by_period() TO xtrole;


COMMENT ON FUNCTION museinvanalysis.populate_invdetail_by_period()
    IS $DOC$Truncates and repopulates the itemsite level data from the transaction history data.$DOC$;
