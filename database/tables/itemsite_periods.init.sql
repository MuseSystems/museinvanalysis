-- File:        itemsite_periods.sql
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
--
DO
    $BODY$
        DECLARE

        BEGIN

            -- Create the table if it does not exist.  Apply deltas if it does and it's needed.
            IF NOT EXISTS(SELECT     true
                          FROM         musextputils.v_basic_catalog
                          WHERE     table_schema_name = 'museinvanalysis'
                                  AND table_name = 'itemsite_periods') THEN
                -- The table doesn't exist, so let's create it.
                CREATE TABLE museinvanalysis.itemsite_periods (
                     itemsite_periods_yearperiod_id     integer NOT NULL REFERENCES public.yearperiod (yearperiod_id)
                    ,itemsite_periods_yearperiod_start  date    NOT NULL
                    ,itemsite_periods_yearperiod_end    date    NOT NULL
                    ,itemsite_periods_yearperiod_closed boolean NOT NULL
                    ,itemsite_periods_period_id         integer NOT NULL REFERENCES public.period (period_id)
                    ,itemsite_periods_period_start      date    NOT NULL
                    ,itemsite_periods_period_end        date    NOT NULL
                    ,itemsite_periods_period_closed     boolean NOT NULL
                    ,itemsite_periods_period_freeze     boolean NOT NULL
                    ,itemsite_periods_period_name       text    NOT NULL
                    ,itemsite_periods_period_quarter    integer NOT NULL
                    ,itemsite_periods_period_number     integer NOT NULL
                    ,itemsite_periods_itemsite_id       integer NOT NULL REFERENCES public.itemsite (itemsite_id)
                    ,PRIMARY KEY(itemsite_periods_period_id, itemsite_periods_itemsite_id)
                );

                ALTER TABLE  museinvanalysis.itemsite_periods OWNER TO admin;

                REVOKE ALL ON TABLE museinvanalysis.itemsite_periods FROM public;
                GRANT ALL ON TABLE museinvanalysis.itemsite_periods TO admin;
                GRANT ALL ON TABLE museinvanalysis.itemsite_periods TO xtrole;

                COMMENT ON TABLE museinvanalysis.itemsite_periods IS
$DOC$A dimension-like table which contains an enumeration of periods and which
itemsite records had relevancy during the time of the period.  In essense this
materializes a query which makes this relevancy determination based on the
inventory transaction history (invhist).

Note that this table departs from our normal surrogate key table structure in
that record identity is close to its natural key.  Since the expectation is that
this table will work much like a materialized view, a surrogate key for the
record ceases to have any real utility.$DOC$;


                -- Let's now add the audit columns and triggers
                PERFORM musextputils.add_common_table_columns(   'museinvanalysis'
                                                                ,'itemsite_periods'
                                                                ,'itemsite_periods_date_created'
                                                                ,'itemsite_periods_role_created'
                                                                ,'itemsite_periods_date_deactivated'
                                                                ,'itemsite_periods_role_deactivated'
                                                                ,'itemsite_periods_date_modified'
                                                                ,'itemsite_periods_wallclock_modified'
                                                                ,'itemsite_periods_role_modified'
                                                                ,'itemsite_periods_row_version_number'
                                                                ,'itemsite_periods_is_active');

                CREATE INDEX itemsite_periods_period_start_idx
                    ON museinvanalysis.itemsite_periods (itemsite_periods_period_start);

                CREATE INDEX itemsite_periods_period_end_idx
                    ON museinvanalysis.itemsite_periods (itemsite_periods_period_end);

                CREATE INDEX itemsite_periods_yearperiod_start_idx
                    ON museinvanalysis.itemsite_periods (itemsite_periods_yearperiod_start);

                CREATE INDEX itemsite_periods_yearperiod_end_idx
                    ON museinvanalysis.itemsite_periods (itemsite_periods_yearperiod_end);

            ELSE
                -- Deltas go here.  Be sure to check if each is really needed.

            END IF;


        END;
    $BODY$;
