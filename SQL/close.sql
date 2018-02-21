SELECT   NAP, F_TERMCSOP, COUNT (DISTINCT F_IVK) as MENESZTETT_DB
    FROM   (SELECT   TRUNC (a.f_int_begin, 'ddd') AS NAP,
    TRUNC (b.f_lezaras, 'ddd') AS MENESZT_NAP,
    b.f_termcsop,
    a.f_ivk
    FROM   afc.t_afc_wflog_lin2 a,
    kontakt.t_lean_alirattipus x,
    kontakt.t_ajanlat_attrib b
    WHERE   a.f_int_begin BETWEEN ADD_MONTHS (
    TRUNC (SYSDATE - 1, 'ddd'),
    -2
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
    AND b.f_termcsop IS NOT NULL
    AND b.f_kecs_pg = 'Feldolgozott')
    WHERE   meneszt_nap = nap
    GROUP BY   NAP, F_TERMCSOP
    ORDER BY   NAP, F_TERMCSOP