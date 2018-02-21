SELECT   TRUNC (f_int_begin, 'ddd') AS NAP,
    tevekenyseg,
    AVG (time) as ATLAG,
    MEDIAN (time) AS MEDIAN,
    COUNT (f_ivk) AS tev_db,
    COUNT (DISTINCT f_ivk) AS kezelt_db
    FROM   (SELECT   x.f_lean_tip,
    TRUNC (a.f_int_begin, 'MM') honap,
    kontakt.basic.get_userid_kiscsoport (a.f_userid)
    AS csoport,
    UPPER (kontakt.basic.get_userid_login (a.f_userid))
    AS login,
    b.f_termcsop,
    b.f_modkod,
    b.f_kpi_kat,
    CASE
    WHEN (   a.f_alirattipusid BETWEEN 1896 AND 1930
    OR a.f_alirattipusid BETWEEN 1944 AND 1947
    OR a.f_alirattipusid = 1952)
    THEN
    kontakt.basic.get_alirattipusid_alirattipus (
    a.f_alirattipusid
    )
    ELSE
    'Egyéb iraton'
    END
    AS tevekenyseg,
    a.feladat,
    (a.f_int_end - a.f_int_begin) * 1440 AS time,
    a.f_ivk,
    a.f_int_begin,
    a.f_int_end
    FROM   afc.t_afc_wflog_lin2 a,
    kontakt.t_lean_alirattipus x,
    kontakt.t_ajanlat_attrib b
    WHERE   a.f_int_begin BETWEEN ADD_MONTHS (
    TRUNC (SYSDATE - 1, 'ddd'),
    -1
    )
    AND  TRUNC (SYSDATE, 'DDD')
    AND (a.f_int_end - a.f_int_begin) * 1440 < 45
    AND (a.f_int_end - a.f_int_begin) * 86400 > 1
    AND afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) IS NOT NULL
    AND a.f_ivk = b.f_ivk(+)
    AND a.f_alirattipusid = x.f_alirattipusid
    AND UPPER (kontakt.basic.get_userid_login (a.f_userid)) NOT IN
    ('MARKIB', 'SZERENCSEK')
    --AND kontakt.basic.get_userid_kiscsoport (a.f_userid) IS NOT NULL
    AND x.f_lean_tip = 'AL'
    AND b.f_termcsop IS NOT NULL)
    GROUP BY   TRUNC (f_int_begin, 'ddd'), tevekenyseg
    ORDER BY   TRUNC (f_int_begin, 'ddd'), tevekenyseg