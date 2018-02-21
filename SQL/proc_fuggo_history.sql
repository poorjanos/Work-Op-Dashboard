CREATE OR REPLACE PROCEDURE POORJ.fuggo_aj_naplo
IS
BEGIN
   INSERT INTO t_fuggo_aj_naplo   (F_IVK,
                            F_IVKWFID,
                            ALAIRAS,
                            KECS,
                            KECS_PG,
                            TERMCSOP,
                            ERKEZETT,
                            F_KPI_KAT,
                            F_PARTNER,
                            F_NEV,
                            F_KTI,
                            TEV,
                            TEV_HOL,
                            AFC_NAPOS,
                            UTSO_OPDOB_IDO,
                            UTSO_OPDOB_USER,
                            LEVALOGATVA)
     select * from t_fuggo_aj;
END fuggo_aj_naplo;
/
