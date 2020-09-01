-- File:        populate_all_inventory_analysis.sql
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
-- This function orchestrates the complete repopulation of the inventory
-- analysis data as well the supporting tables.
--

CREATE OR REPLACE FUNCTION museinvanalysis.populate_all_inventory_analysis()
    RETURNS void AS
        $BODY$
            BEGIN

                PERFORM museinvanalysis.populate_itemsite_periods();
                PERFORM museinvanalysis.populate_invdetail_periods();

                PERFORM museinvanalysis.populate_itemsite_by_period();
                PERFORM museinvanalysis.populate_invdetail_by_period();

            END;
        $BODY$
    LANGUAGE plpgsql VOLATILE;

ALTER FUNCTION museinvanalysis.populate_all_inventory_analysis()
    OWNER TO admin;

REVOKE EXECUTE ON FUNCTION museinvanalysis.populate_all_inventory_analysis() FROM public;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_all_inventory_analysis() TO admin;
GRANT EXECUTE ON FUNCTION museinvanalysis.populate_all_inventory_analysis() TO xtrole;


COMMENT ON FUNCTION museinvanalysis.populate_all_inventory_analysis() IS
$DOC$This function orchestrates the complete repopulation of the inventory analysis
data as well the supporting tables.$DOC$;
