CREATE OR REPLACE PROCEDURE POORJ.fuggo_aj
IS
BEGIN
   EXECUTE IMMEDIATE 'TRUNCATE TABLE t_fuggo_aj';

   COMMIT;

   INSERT INTO t_fuggo_aj   (F_IVK,
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
     SELECT DISTINCT t_ajanlat_attrib.f_ivk,
                f_ivkwfid,
                basic.ivk_attrib_date(t_ajanlat_attrib.f_ivk, 32) alairas,
                basic.aivk_utolso_kecs(t_ajanlat_attrib.f_ivk) kecs,
                basic.aivk_utolso_kecs_pg(t_ajanlat_attrib.f_ivk) kecs_pg,
                t_ajanlat_attrib.f_termcsop,
                TRUNC(t_ajanlat_attrib.f_erkezes) erkezett,
                t_ajanlat_attrib.f_kpi_kat,
                f_partner,
                f_nev,
                f_kti,
                basic.get_alirattipusid_alirattipus(f_alirattipusid) tev,
                basic.ivkwfid_hol(f_ivkwfid) tev_hol,
                basic.aivk_atfutas(t_ajanlat_attrib.f_ivk) afc_napos,
                basic.ivk_wf_idopont(t_ajanlat_attrib.f_ivk, 1732) utso_opdob_ido,
                basic_km.ivk_wf_user(t_ajanlat_attrib.f_ivk, 1732, 'last') utso_opdob_user,
                SYSDATE levalogatva
  FROM t_ajanlat_attrib
  LEFT OUTER JOIN t_cache_partner
    ON (f_partner = f_torzsszam)
  LEFT OUTER JOIN t_irat_tevlog
    ON (t_ajanlat_attrib.f_ivk = t_irat_tevlog.f_ivk AND
       t_irat_tevlog.f_end IS NULL AND
       f_alirattipusid IN
       (SELECT DISTINCT f_alirattipusid
           FROM t_alirattipus
          WHERE f_irat_tipusid = 461))
 WHERE f_erkezes BETWEEN
       sysdate-90 AND
       sysdate
   AND f_kecs_pg != 'Feldolgozott'
   AND basic.aivk_utolso_kecs_pg(t_ajanlat_attrib.f_ivk) != 'Feldolgozott';
   COMMIT;
END fuggo_aj;
/
