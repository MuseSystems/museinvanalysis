-- File:        populate_itemsite_periods.sql
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
-- Truncates and rebuilds the museinvanalysis.itemsite_periods table from source
-- data.
--

CREATE OR REPLACE FUNCTION museinvanalysis.populate_itemsite_periods()
    RETURNS void AS
        $BODY$
            TRUNCATE TABLE museinvanalysis.itemsite_periods;

            INSERT INTO museinvanalysis.itemsite_periods
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
            FROM museinvanalysis.v_itemsite_periods;
        $BODY$
    LANGUAGE sql VOLATILE;

ALTER FUNCTION museinvanalysis.populate_itemsite_periods()
    OWNER TO admin;

REVOKE EXECUTE ON FUNCTION museinvanalysis.populate_itemsite_periods() FROM public;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_itemsite_periods() TO admin;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_itemsite_periods() TO xtrole;


COMMENT ON FUNCTION museinvanalysis.populate_itemsite_periods()
    IS $DOC$Truncates and rebuilds the museinvanalysis.itemsite_periods table from source data.$DOC$;
