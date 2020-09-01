-- File:        invdetail_periods.sql
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
                                  AND table_name = 'invdetail_periods') THEN
                -- The table doesn't exist, so let's create it.
                CREATE TABLE museinvanalysis.invdetail_periods (
                     invdetail_periods_id                bigserial NOT NULL PRIMARY KEY
                    ,invdetail_periods_yearperiod_id     integer   NOT NULL REFERENCES public.yearperiod (yearperiod_id)
                    ,invdetail_periods_yearperiod_start  date      NOT NULL
                    ,invdetail_periods_yearperiod_end    date      NOT NULL
                    ,invdetail_periods_yearperiod_closed boolean   NOT NULL
                    ,invdetail_periods_period_id         integer   NOT NULL REFERENCES public.period (period_id)
                    ,invdetail_periods_period_start      date      NOT NULL
                    ,invdetail_periods_period_end        date      NOT NULL
                    ,invdetail_periods_period_closed     boolean   NOT NULL
                    ,invdetail_periods_period_freeze     boolean   NOT NULL
                    ,invdetail_periods_period_name       text      NOT NULL
                    ,invdetail_periods_period_quarter    integer   NOT NULL
                    ,invdetail_periods_period_number     integer   NOT NULL
                    ,invdetail_periods_itemsite_id       integer   NOT NULL REFERENCES public.itemsite (itemsite_id)
                    -- The next two columns must be nullable as xtuple allows
                    -- some form of that.
                    ,invdetail_periods_location_id       integer REFERENCES public.location (location_id)
                    ,invdetail_periods_ls_id             integer REFERENCES public.ls (ls_id)
                );

                CREATE INDEX invdetail_periods_natural_key_udx
                    ON museinvanalysis.invdetail_periods
                    (    invdetail_periods_period_id
                        ,invdetail_periods_itemsite_id
                        ,COALESCE(invdetail_periods_location_id, -1)
                        ,COALESCE(invdetail_periods_ls_id, -1));

                ALTER TABLE  museinvanalysis.invdetail_periods OWNER TO admin;

                REVOKE ALL ON TABLE museinvanalysis.invdetail_periods FROM public;
                GRANT ALL ON TABLE museinvanalysis.invdetail_periods TO admin;
                GRANT ALL ON TABLE museinvanalysis.invdetail_periods TO xtrole;

                COMMENT ON TABLE museinvanalysis.invdetail_periods IS
$DOC$A dimension-like table which contains an enumeration of periods and which
Location/Lot/Serial records had relevancy during the time of the period.  In
essense this materializes a query which makes this relevancy determination based
on the inventory transaction history (invhist).

We use a surrogate key here instead of the more natural-like compound key as
some values (ls_id, location_id) must allow null values.$DOC$;

                -- Let's now add the audit columns and triggers
                PERFORM musextputils.add_common_table_columns(   'museinvanalysis'
                                                                ,'invdetail_periods'
                                                                ,'invdetail_periods_date_created'
                                                                ,'invdetail_periods_role_created'
                                                                ,'invdetail_periods_date_deactivated'
                                                                ,'invdetail_periods_role_deactivated'
                                                                ,'invdetail_periods_date_modified'
                                                                ,'invdetail_periods_wallclock_modified'
                                                                ,'invdetail_periods_role_modified'
                                                                ,'invdetail_periods_row_version_number'
                                                                ,'invdetail_periods_is_active');

                CREATE INDEX invdetail_periods_period_start_idx
                    ON museinvanalysis.invdetail_periods (invdetail_periods_period_start);

                CREATE INDEX invdetail_periods_period_end_idx
                    ON museinvanalysis.invdetail_periods (invdetail_periods_period_end);

                CREATE INDEX invdetail_periods_yearperiod_start_idx
                    ON museinvanalysis.invdetail_periods (invdetail_periods_yearperiod_start);

                CREATE INDEX invdetail_periods_yearperiod_end_idx
                    ON museinvanalysis.invdetail_periods (invdetail_periods_yearperiod_end);

                CREATE INDEX invdetail_periods_ls_idx
                    ON museinvanalysis.invdetail_periods (invdetail_periods_ls_id);

                CREATE INDEX invdetail_periods_location_idx
                    ON museinvanalysis.invdetail_periods (invdetail_periods_location_id);

            ELSE
                -- Deltas go here.  Be sure to check if each is really needed.

            END IF;


        END;
    $BODY$;
