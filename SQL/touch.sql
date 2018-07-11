 SELECT   TRUNC (a.f_int_begin, 'ddd') AS NAP,
                 b.f_termcsop,
                 COUNT (DISTINCT a.f_ivk) AS ERINTETT_DB,
                 SUM(f_int_end-f_int_begin)*1440/60 as MUNKA_ORA
          FROM   afc.t_afc_wflog_lin2 a,
                 kontakt.t_lean_alirattipus x,
                 kontakt.t_ajanlat_attrib b
         WHERE   a.f_int_begin BETWEEN ADD_MONTHS (TRUNC (SYSDATE - 1, 'ddd'), -2)
                                   AND  TRUNC (SYSDATE, 'DDD')
                 AND (a.f_int_end - a.f_int_begin) * 1440 < 45
                 AND (a.f_int_end - a.f_int_begin) * 86400 > 1
                 AND afc.afc_wflog_intezkedes (a.f_ivkwfid, a.f_logid) IS NOT NULL
                 AND a.f_ivk = b.f_ivk(+)
                 AND a.f_alirattipusid = x.f_alirattipusid
                 AND UPPER (kontakt.basic.get_userid_login (a.f_userid)) NOT IN
                          ('MARKIB', 'SZERENCSEK')
                 AND x.f_lean_tip = 'AL'
                 AND b.f_termcsop IS NOT NULL
      GROUP BY   TRUNC (a.f_int_begin, 'ddd'), b.f_termcsop
      ORDER BY   TRUNC (a.f_int_begin, 'ddd'), b.f_termcsop