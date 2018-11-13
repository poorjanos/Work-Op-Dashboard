SELECT   levalogatva, f_ivk,
         kecs,
    kecs_pg,
    termcsop,
    erkezett,
    tev,
    k2017.basic.munkanapok@dl_kontakt_poorj(erkezett, levalogatva) as erk_mnap
    FROM   t_fuggo_aj