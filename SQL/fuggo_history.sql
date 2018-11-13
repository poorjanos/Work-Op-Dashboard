SELECT   levalogatva, f_ivk,
         kecs,
    kecs_pg,
    termcsop,
    erkezett,
    tev
    FROM   t_fuggo_aj_naplo
    where trunc(levalogatva, 'ddd') > add_months(trunc(sysdate, 'mm'), -2)