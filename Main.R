# Redirect stdout to logfile
scriptLog <- file("scriptLog", open = "wt")
sink(scriptLog, type = "message")

# Load required libs
library(config)
library(here)
library(dplyr)
library(lubridate)
library(tidyr)


# Quit if sysdate == weekend ------------------------------------------------------------
stopifnot(!(strftime(Sys.Date(), "%u") == 6 | strftime(Sys.Date(), "%u") == 7))

#########################################################################################
# Data Extraction #######################################################################
#########################################################################################

# Create dirs (dir.create() does not crash when dir already exists)
dir.create(here::here("Data"), showWarnings = FALSE)
dir.create(here::here("Reports"), showWarnings = FALSE)
dir.create(here::here("SQL"), showWarnings = FALSE)

# Connect to Oracle (Kont@kt:MMBDBIKON)
# Set JAVA_HOME, set max. memory, and load rJava library
Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre1.8.0_171")
options(java.parameters = "-Xmx2g")
library(rJava)

# Output Java version
.jinit()
print(.jcall("java/lang/System", "S", "getProperty", "java.version"))

# Load RJDBC library
library(RJDBC)

# Create connection driver and open connection
jdbcDriver <-
  JDBC(
    driverClass = "oracle.jdbc.OracleDriver",
    classPath = "C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar"
  )

# Get  credentials
kontakt <-
  config::get("kontakt",
    file = "C:\\Users\\PoorJ\\Projects\\config.yml"
  )

datamnr <-
  config::get("datamnr",
    file = "C:\\Users\\PoorJ\\Projects\\config.yml"
  )

# Define SQL parser
readQuery <-
  function(file)
    paste(readLines(file, warn = FALSE), collapse = "\n")

# Get SQL scripts
forg <-
  readQuery(here::here("SQL", "forgalom.sql"))
fuggo <-
  readQuery(here::here("SQL", "fuggo.sql"))
fuggo_history <-
  readQuery(here::here("SQL", "fuggo_history.sql"))
touch <-
  readQuery(here::here("SQL", "touch.sql"))
close <-
  readQuery(here::here("SQL", "close.sql"))
ctime <-
  readQuery(here::here("SQL", "ctime.sql"))

# Open connection Kontakt
jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = kontakt$server,
    user = kontakt$uid,
    password = kontakt$pwd
  )

# Run queries Kontakt
t_forgalom <- dbGetQuery(jdbcConnection, forg)
t_touch <- dbGetQuery(jdbcConnection, touch)
t_close <- dbGetQuery(jdbcConnection, close)
t_ctime <- dbGetQuery(jdbcConnection, ctime)

# Close connection Kontakt
dbDisconnect(jdbcConnection)


# Open connection Datamnr
jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = datamnr$server,
    user = datamnr$uid,
    password = datamnr$pwd
  )

# Run queries Datamnr
t_fuggo <- dbGetQuery(jdbcConnection, fuggo)
t_fuggo_history <- dbGetQuery(jdbcConnection, fuggo_history)

# Close connection Datamnr
dbDisconnect(jdbcConnection)

#########################################################################################
# Compute Pending Volume Metrics ########################################################
#########################################################################################

# Select for day
t_fuggo[t_fuggo$KECS_PG %in% c("Feldolgozandó", "Feldogozandó"), "KECS_PG"] <-
  "Folyamatban"

# Page 1: main
status_main <- group_by(t_fuggo) %>%
  summarize(
    DARAB = round(length(F_IVK), 0),
    ELTELT_MNAP_ATL = round(mean(ERK_MNAP), 2),
    ELTELT_MNAP_MED = round(median(ERK_MNAP), 2)
  )

write.csv(
  status_main,
  here::here(
    "Data",
    "fuggo_status_main.csv"
  ),
  row.names = FALSE
)


termek <- group_by(t_fuggo, TERMCSOP) %>%
  summarize(
    DARAB = round(length(F_IVK), 0),
    ELTELT_MNAP = round(mean(ERK_MNAP), 2)
  ) %>%
  gather(MUTATÓ, ÉRTÉK, DARAB:ELTELT_MNAP)

write.csv(
  termek,
  here::here("Data", "fuggo_termek.csv"),
  row.names = FALSE
)


status <- group_by(t_fuggo, TERMCSOP, KECS_PG) %>%
  summarize(
    DARAB = round(length(F_IVK), 0),
    ELTELT_MNAP = round(mean(ERK_MNAP), 2)
  ) %>%
  gather(MUTATÓ, ÉRTÉK, DARAB:ELTELT_MNAP)

write.csv(
  status,
  here::here("Data", "fuggo_status.csv"),
  row.names = FALSE
)


# Page 2: status
status_kecs_main <- group_by(t_fuggo, KECS_PG) %>%
  summarize(
    DARAB = round(length(F_IVK), 0),
    ELTELT_MNAP = round(mean(ERK_MNAP), 2)
  )

write.csv(
  status_kecs_main,
  here::here(
    "Data",
    "fuggo_status_kecs_main.csv"
  ),
  row.names = FALSE
)


status_varak <-
  group_by(t_fuggo[t_fuggo$KECS_PG == "Várakozó", ], TERMCSOP, KECS) %>%
  summarize(
    DARAB = round(length(F_IVK), 0),
    ELTELT_MNAP = round(mean(ERK_MNAP), 2)
  ) %>%
  gather(MUTATÓ, ÉRTÉK, DARAB:ELTELT_MNAP)

write.csv(
  status_varak,
  here::here(
    "Data",
    "fuggo_status_varak.csv"
  ),
  row.names = FALSE
)


status_foly <-
  group_by(t_fuggo[t_fuggo$KECS_PG == "Folyamatban", ], TERMCSOP, KECS) %>%
  summarize(
    DARAB = round(length(F_IVK), 0),
    ELTELT_MNAP = round(mean(ERK_MNAP), 2)
  ) %>%
  gather(MUTATÓ, ÉRTÉK, DARAB:ELTELT_MNAP)

write.csv(
  status_foly,
  here::here(
    "Data",
    "fuggo_status_foly.csv"
  ),
  row.names = FALSE
)


# Time series
t_fuggo_history[t_fuggo_history$KECS_PG %in% c("Feldolgozandó", "Feldogozandó"), "KECS_PG"] <-
  "Folyamatban"
t_fuggo_history$DATUM <-
  as.character(floor_date(ymd_hms(t_fuggo_history$LEVALOGATVA), "day"))


fuggo_hist <- group_by(t_fuggo_history, DATUM, KECS_PG) %>%
  summarize(
    DARAB = length(F_IVK)
  )

write.csv(
  fuggo_hist,
  here::here("Data", "fuggo_hist.csv"),
  row.names = FALSE
)


fuggo_hist_term <-
  group_by(t_fuggo_history, DATUM, KECS_PG, TERMCSOP) %>%
  summarize(
    DARAB = length(F_IVK)
  )

write.csv(
  fuggo_hist_term,
  here::here(
    "Data",
    "fuggo_hist_term.csv"
  ),
  row.names = FALSE
)



#########################################################################################
# Volumes: incoming & processed #########################################################
#########################################################################################

# Transform
dataclear <- function(x, period = "M") {
  # Setting period
  # M: one month
  # H: six months
  x$NAP <- ymd_hms(x$NAP)

  # Define time span
  if (period == "M") {
    x <- x %>% filter(NAP >= Sys.Date() - 30)
  } else if (period == "H") {
    x <- x %>% filter(NAP >= Sys.Date() - 180)
  }

  x <- x[!day(x$NAP) == day(Sys.Date()), ] # exclude sysdate
  x$NAP <- as.character(x$NAP)
  x[is.na(x)] <- "Ismeretlen"
  return(x)
}

# Gen one month daily data
forg <-
  group_by(dataclear(t_forgalom, "M"), TIPUS, NAP, KOTVENYESITES) %>%
  summarize(DARAB = sum(DARAB))
forg[forg$TIPUS == "ERKEZETT", "TIPUS"] <- "Beérkezett"
forg[forg$TIPUS == "LEZART", "TIPUS"] <- "Kötvényesített"

write.csv(forg,
  here::here("Data", "forg.csv"),
  row.names = FALSE
)


forg_termcsop <-
  group_by(dataclear(t_forgalom, "M"), TIPUS, NAP, KOTVENYESITES, F_TERMCSOP) %>%
  summarize(DARAB = sum(DARAB))
forg_termcsop[forg_termcsop$TIPUS == "ERKEZETT", "TIPUS"] <-
  "Beérkezett"
forg_termcsop[forg_termcsop$TIPUS == "LEZART", "TIPUS"] <-
  "Kötvényesített"

write.csv(
  forg_termcsop,
  here::here("Data", "forg_term.csv"),
  row.names = FALSE
)


# Gen six month weekly data
forg_weekly <- dataclear(t_forgalom, "H") %>%
  mutate(HET = paste0(year(NAP), "/", ifelse(week(NAP) < 10, paste0("0", week(NAP)), week(NAP)))) %>%
  group_by(TIPUS, HET, KOTVENYESITES) %>%
  summarize(DARAB = sum(DARAB))

forg_weekly[forg_weekly$TIPUS == "ERKEZETT", "TIPUS"] <- "Beérkezett"
forg_weekly[forg_weekly$TIPUS == "LEZART", "TIPUS"] <- "Kötvényesített"

write.csv(forg_weekly,
  here::here("Data", "forg_weekly.csv"),
  row.names = FALSE
)


forg_termcsop_weekly <- dataclear(t_forgalom, "H") %>%
  mutate(HET = paste0(year(NAP), "/", ifelse(week(NAP) < 10, paste0("0", week(NAP)), week(NAP)))) %>%
  group_by(TIPUS, HET, KOTVENYESITES, F_TERMCSOP) %>%
  summarize(DARAB = sum(DARAB))
  
forg_termcsop_weekly[forg_termcsop_weekly$TIPUS == "ERKEZETT", "TIPUS"] <- "Beérkezett"
forg_termcsop_weekly[forg_termcsop_weekly$TIPUS == "LEZART", "TIPUS"] <- "Kötvényesített"

write.csv(
  forg_termcsop_weekly,
  here::here("Data", "forg_term_weekly.csv"),
  row.names = FALSE
)


#########################################################################################
# Workout ###############################################################################
#########################################################################################

workout <-
  group_by(dataclear(t_forgalom[t_forgalom$TIPUS == "ERKEZETT", ]), NAP, F_KECS_PG) %>%
  summarize(DARAB = sum(DARAB))
workout[workout$F_KECS_PG %in% c("Feldolgozandó", "Feldogozandó"), "F_KECS_PG"] <-
  "Folyamatban"

write.csv(
  workout,
  here::here("Data", "workout.csv"),
  row.names = FALSE
)


workout_term <-
  group_by(dataclear(t_forgalom[t_forgalom$TIPUS == "ERKEZETT", ]), NAP, F_TERMCSOP, F_KECS_PG) %>%
  summarize(DARAB = sum(DARAB))
workout_term[workout_term$F_KECS_PG %in% c("Feldolgozandó", "Feldogozandó"), "F_KECS_PG"] <-
  "Folyamatban"

write.csv(
  workout_term,
  here::here("Data", "workout_term.csv"),
  row.names = FALSE
)



#########################################################################################
# Efficiency Metrics ####################################################################
#########################################################################################

# tch, closed, cklido transform
t_touch$NAP <- floor_date(ymd_hms(t_touch$NAP), "day")
t_close$NAP <- floor_date(ymd_hms(t_close$NAP), "day")
t_ctime$NAP <- floor_date(ymd_hms(t_ctime$NAP), "day")

t_touch_full <-
  left_join(t_touch, t_close, by = c("NAP", "F_TERMCSOP"))
t_touch_full[is.na(t_touch_full)] <- 0
t_touch_full$MUNKA_ORA <- round(t_touch_full$MUNKA_ORA, 2)

write.csv(
  t_touch_full,
  here::here("Data", "touch_close.csv"),
  row.names = FALSE
)

write.csv(
  t_ctime,
  here::here("Data", "ctime.csv"),
  row.names = FALSE
)


# Knit flexdahsboard
library(rmarkdown)
render(here::here(
  "Reports",
  "Op_dashboard.Rmd"
))

# Copy to public folder
try(file.copy(
  here::here(
    "Reports",
    "Op_dashboard.html"
  ),
  "C:/Users/PoorJ/Publish/Dashboards",
  overwrite = T
))


# Redirect stdout back to console
sink(type = "message")
close(scriptLog)
