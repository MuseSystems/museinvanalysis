-- File:        invdetail_by_period.sql
-- Location:    /home/scb/Dropbox/muse/src/products/xtuple/museinvanalysis/database/tables
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

DO
    $BODY$
        DECLARE

        BEGIN

            -- Create the table if it does not exist.  Apply deltas if it does and it's needed.
            IF NOT EXISTS(SELECT     true
                          FROM         musextputils.v_basic_catalog
                          WHERE     table_schema_name = 'museinvanalysis'
                                  AND table_name = 'invdetail_by_period') THEN
                -- The table doesn't exist, so let's create it.
                CREATE TABLE museinvanalysis.invdetail_by_period (
                     invdetail_by_period_id               bigserial NOT NULL PRIMARY KEY
                    ,invdetail_by_period_period_id        integer   NOT NULL REFERENCES public.period (period_id)
                    ,invdetail_by_period_itemsite_id      integer   NOT NULL REFERENCES public.itemsite (itemsite_id)
                    ,invdetail_by_period_location_id      integer   REFERENCES public.location (location_id)
                    ,invdetail_by_period_ls_id            integer   REFERENCES public.ls (ls_id)
                    ,invdetail_by_period_yearperiod_id    integer   NOT NULL REFERENCES public.yearperiod (yearperiod_id)
                    ,invdetail_by_period_qty_in           numeric   NOT NULL DEFAULT 0.0
                    ,invdetail_by_period_value_in         numeric   NOT NULL DEFAULT 0.00
                    ,invdetail_by_period_adjust_value_in  numeric   NOT NULL DEFAULT 0.00
                    ,invdetail_by_period_qty_out          numeric   NOT NULL DEFAULT 0.0
                    ,invdetail_by_period_value_out        numeric   NOT NULL DEFAULT 0.00
                    ,invdetail_by_period_adjust_value_out numeric   NOT NULL DEFAULT 0.00
                    ,invdetail_by_period_ending_qoh       numeric   NOT NULL DEFAULT 0.0
                    ,invdetail_by_period_ending_value     numeric   NOT NULL DEFAULT 0.00
                    ,invdetail_by_period_ending_unitcost  numeric   NOT NULL DEFAULT 0.00
                );

                CREATE INDEX invdetail_by_period_natural_key_udx
                    ON museinvanalysis.invdetail_by_period
                    (    invdetail_by_period_period_id
                        ,invdetail_by_period_itemsite_id
                        ,COALESCE(invdetail_by_period_location_id, -1)
                        ,COALESCE(invdetail_by_period_ls_id, -1));

                ALTER TABLE  museinvanalysis.invdetail_by_period OWNER TO admin;

                REVOKE ALL ON TABLE museinvanalysis.invdetail_by_period FROM public;
                GRANT ALL ON TABLE museinvanalysis.invdetail_by_period TO admin;
                GRANT ALL ON TABLE museinvanalysis.invdetail_by_period TO xtrole;

                COMMENT ON TABLE museinvanalysis.invdetail_by_period IS
$DOC$A fact-like table containing location/lot/serial detail inventory quantitative
data by fiscal period.$DOC$;


                -- Let's now add the audit columns and triggers
                PERFORM musextputils.add_common_table_columns(   'museinvanalysis'
                                                                ,'invdetail_by_period'
                                                                ,'invdetail_by_period_date_created'
                                                                ,'invdetail_by_period_role_created'
                                                                ,'invdetail_by_period_date_deactivated'
                                                                ,'invdetail_by_period_role_deactivated'
                                                                ,'invdetail_by_period_date_modified'
                                                                ,'invdetail_by_period_wallclock_modified'
                                                                ,'invdetail_by_period_role_modified'
                                                                ,'invdetail_by_period_row_version_number'
                                                                ,'invdetail_by_period_is_active');

                CREATE INDEX invdetail_by_period_period_idx
                    ON museinvanalysis.invdetail_by_period
                        (invdetail_by_period_period_id);

                CREATE INDEX invdetail_by_period_period_itemsite_idx
                    ON museinvanalysis.invdetail_by_period
                        (invdetail_by_period_itemsite_id);

                CREATE INDEX invdetail_by_period_period_itemsite_ls_idx
                    ON museinvanalysis.invdetail_by_period
                        (invdetail_by_period_itemsite_id, invdetail_by_period_ls_id);

                CREATE INDEX invdetail_by_period_period_location_idx
                    ON museinvanalysis.invdetail_by_period
                        (invdetail_by_period_location_id);

            ELSE
                -- Deltas go here.  Be sure to check if each is really needed.

            END IF;


        END;
    $BODY$;
