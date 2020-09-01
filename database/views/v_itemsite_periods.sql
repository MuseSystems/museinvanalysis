-- File:        v_itemsite_periods.sql
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
-- Matches itemsite transactional history to fiscal periods and ensures that all
-- periods, including dormant periods, are represented.
--

CREATE OR REPLACE VIEW museinvanalysis.v_itemsite_periods AS
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
        ,items.itemsite_qtyonhand AS current_qtyonhand
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
                    ,min(invhist_transdate::date) AS transaction_first_date
                    ,max(invhist_transdate::date) AS transaction_last_date
                    ,itemsite_qtyonhand <> 0.0 AS has_inventory
                    ,itemsite_qtyonhand
                FROM invhist
                    JOIN itemsite
                        ON invhist_itemsite_id = itemsite_id
                WHERE invhist_posted
                GROUP BY itemsite_id) items
            ON items.transaction_first_date <= time.period_end AND
                (items.transaction_last_date >= time.period_start OR
                    items.has_inventory);

ALTER VIEW museinvanalysis.v_itemsite_periods OWNER TO admin;

REVOKE ALL ON TABLE museinvanalysis.v_itemsite_periods FROM public;
GRANT ALL ON TABLE museinvanalysis.v_itemsite_periods TO admin;
GRANT ALL ON TABLE museinvanalysis.v_itemsite_periods TO xtrole;

COMMENT ON VIEW museinvanalysis.v_itemsite_periods IS
$DOC$Matches itemsite transactional history to fiscal periods and ensures that all
periods, including dormant periods, are represented.$DOC$;