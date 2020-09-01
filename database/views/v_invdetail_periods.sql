-- File:        v_invdetail_periods.sql
-- Location:    /home/scb/Dropbox/muse/src/products/xtuple/museinvanalysis/database/views
-- Project:     Muse Systems Inventory Analsysis for xTuple ERP
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
-- Matches Location/LS transactional history to fiscal periods and ensures that
-- all periods, including dormant periods, are represented.
--

CREATE OR REPLACE VIEW museinvanalysis.v_invdetail_periods AS
    SELECT
         time.yearperiod_id
        ,time.yearperiod_start
        ,time.yearperiod_end
        ,time.yearperiod_closed
        ,time.period_id
        ,time.period_start
        ,time.period_end
        ,time.period_closed
        ,time.period_freeze
        ,time.period_name
        ,time.period_quarter
        ,time.period_number
        ,items.itemsite_id
        ,nullif(items.location_id, -1) AS location_id
        ,nullif(items.ls_id, -1) AS ls_id
        ,items.itemloc_qty AS current_qtyonhand
        ,items.transaction_first_date
        ,items.transaction_last_date
    FROM
       (SELECT
            *
        FROM public.period p
                JOIN public.yearperiod yp
                    ON p.period_yearperiod_id = yp.yearperiod_id
        WHERE p.period_start <= now()::date) time
        JOIN (  SELECT
                     itemsite_id
                    ,invdetail_location_id AS location_id
                    ,invdetail_ls_id AS ls_id
                    ,min(invhist_transdate::date) AS transaction_first_date
                    ,max(invhist_transdate::date) AS transaction_last_date
                    ,coalesce(itemloc_qty, 0.0) <> 0.0 AS has_inventory
                    ,coalesce(itemloc_qty, 0.0) AS itemloc_qty
                FROM invhist
                    JOIN itemsite
                        ON invhist_itemsite_id = itemsite_id
                    JOIN invdetail
                        ON invdetail_invhist_id = invhist_id
                    LEFT OUTER JOIN (SELECT
                                         itemloc_itemsite_id
                                        ,itemloc_location_id
                                        ,itemloc_ls_id
                                        ,sum(itemloc_qty) AS itemloc_qty
                                     FROM
                                        public.itemloc
                                     GROUP BY
                                         itemloc_itemsite_id
                                        ,itemloc_location_id
                                        ,itemloc_ls_id) detail
                        ON detail.itemloc_itemsite_id = itemsite_id AND
                            detail.itemloc_location_id = invdetail_location_id AND
                            detail.itemloc_ls_id = invdetail_ls_id
                WHERE invhist_posted
                GROUP BY
                     itemsite_id
                    ,invdetail_location_id
                    ,invdetail_ls_id
                    ,itemloc_qty) items
            ON items.transaction_first_date <= time.period_end AND
                (items.transaction_last_date >= time.period_start OR
                    items.has_inventory);

ALTER VIEW museinvanalysis.v_invdetail_periods OWNER TO admin;

REVOKE ALL ON TABLE museinvanalysis.v_invdetail_periods FROM public;
GRANT ALL ON TABLE museinvanalysis.v_invdetail_periods TO admin;
GRANT ALL ON TABLE museinvanalysis.v_invdetail_periods TO xtrole;

COMMENT ON VIEW museinvanalysis.v_invdetail_periods IS
$DOC$Matches Location/LS transactional history to fiscal periods and ensures that all
periods, including dormant periods, are represented.$DOC$;
