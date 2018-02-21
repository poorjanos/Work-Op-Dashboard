    SELECT   'ERKEZETT' AS tipus,
                           TRUNC (f_erkezes, 'ddd') AS nap,
                           CASE
                           WHEN f_kecs = 'Lezárt központi menesztett' THEN 'Automatikus'
                           ELSE 'Manualis'
                           END
                           AS kotvenyesites,
                           f_termcsop,
                           f_kecs_pg,
                           f_kecs,
                           COUNT (f_ivk) AS darab
                           FROM   kontakt.t_ajanlat_attrib
                           WHERE   f_erkezes BETWEEN ADD_MONTHS (TRUNC (SYSDATE, 'ddd'), -1)
                           AND  TRUNC (SYSDATE, 'ddd')
                           AND f_erkezes IS NOT NULL
                           AND f_kecs_pg IS NOT NULL
                           GROUP BY   'ERKEZETT',
                           TRUNC (f_erkezes, 'ddd'),
                           CASE
                           WHEN f_kecs = 'Lezárt központi menesztett' THEN 'Automatikus'
                           ELSE 'Manualis'
                           END,
                           f_termcsop,
                           f_kecs_pg,
                           f_kecs
                           UNION
                           SELECT   'LEZART' AS tipus,
                           TRUNC (f_lezaras, 'ddd') AS nap,
                           CASE
                           WHEN f_kecs = 'Lezárt központi menesztett' THEN 'Automatikus'
                           ELSE 'Manualis'
                           END
                           AS kotvenyesites,
                           f_termcsop,
                           f_kecs_pg,
                           f_kecs,
                           COUNT (f_ivk) AS darab
                           FROM   kontakt.t_ajanlat_attrib
                           WHERE   f_erkezes BETWEEN ADD_MONTHS (TRUNC (SYSDATE, 'mm'), -4)
                           AND  TRUNC (SYSDATE, 'ddd')
                           AND f_lezaras BETWEEN ADD_MONTHS (TRUNC (SYSDATE, 'ddd'), -1)
                           AND  TRUNC (SYSDATE, 'ddd')
                           AND f_erkezes IS NOT NULL
                           AND f_lezaras IS NOT NULL
                           AND f_kecs_pg IS NOT NULL
                           GROUP BY   'LEZART',
                           TRUNC (f_lezaras, 'ddd'),
                           CASE
                           WHEN f_kecs = 'Lezárt központi menesztett' THEN 'Automatikus'
                           ELSE 'Manualis'
                           END,
                           f_termcsop,
                           f_kecs_pg,
                           f_kecs