-- File:        populate_invdetail_periods.sql
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
-- Truncates and rebuilds the museinvanalysis.invdetail_periods table from source
-- data.
--

CREATE OR REPLACE FUNCTION museinvanalysis.populate_invdetail_periods()
    RETURNS void AS
        $BODY$
            TRUNCATE TABLE museinvanalysis.invdetail_periods;

            INSERT INTO museinvanalysis.invdetail_periods
                (   invdetail_periods_yearperiod_id
                   ,invdetail_periods_yearperiod_start
                   ,invdetail_periods_yearperiod_end
                   ,invdetail_periods_yearperiod_closed
                   ,invdetail_periods_period_id
                   ,invdetail_periods_period_start
                   ,invdetail_periods_period_end
                   ,invdetail_periods_period_closed
                   ,invdetail_periods_period_freeze
                   ,invdetail_periods_period_name
                   ,invdetail_periods_period_quarter
                   ,invdetail_periods_period_number
                   ,invdetail_periods_itemsite_id
                   ,invdetail_periods_location_id
                   ,invdetail_periods_ls_id)
            SELECT
                 yearperiod_id
                ,yearperiod_start
                ,yearperiod_end
                ,yearperiod_closed
                ,period_id
                ,period_start
                ,period_end
                ,period_closed
                ,period_freeze
                ,period_name
                ,period_quarter
                ,period_number
                ,itemsite_id
                ,location_id
                ,ls_id
            FROM museinvanalysis.v_invdetail_periods;
        $BODY$
    LANGUAGE sql VOLATILE;

ALTER FUNCTION museinvanalysis.populate_invdetail_periods()
    OWNER TO admin;

REVOKE EXECUTE ON FUNCTION museinvanalysis.populate_invdetail_periods() FROM public;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_invdetail_periods() TO admin;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_invdetail_periods() TO xtrole;


COMMENT ON FUNCTION museinvanalysis.populate_invdetail_periods()
    IS $DOC$Truncates and rebuilds the museinvanalysis.invdetail_periods table from source data.$DOC$;