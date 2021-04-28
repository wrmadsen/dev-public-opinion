###### Load data

# Covariates ----

## English speakers ----
# English speakers data from the UN
un_lang_raw <- read_csv("data-raw/covariates/UNdata_Export_20210203_194758725.csv")

# English speakers data pasted from Ethnologue
ethno_raw <- read_excel("data-raw/covariates/ethnologue_english.xlsx")

# English speakers data from Wikipedia
wiki_raw <- read_excel("data-raw/covariates/english_wiki.xlsx", skip = 1)

# Corruption perception index
cpi_raw <- read_excel("data-raw/covariates/CPI2020_GlobalTablesTS_210125.xlsx",
                      sheet = "CPI Timeseries 2012 - 2020",
                      skip = 2)

# WGI data, voice and accountability index
wgi_raw <- read_excel("data-raw/covariates/wgidataset.xlsx", sheet = "VoiceandAccountability", skip = 12)

## Population ----
# UN population estimates
## https://population.un.org/wpp/Download/Standard/CSV/
pop_raw <- read_csv("data-raw/covariates/WPP2019_TotalPopulationBySex.csv")

## GDP PPP----
## from World Bank
## https://data.worldbank.org/indicator/NY.GDP.MKTP.PP.KD
gdp_ppp_raw <- read_csv("data-raw/covariates/API_NY.GDP.MKTP.PP.KD_DS2_en_csv_v2_1928416.csv", skip = 3)

# GDL, sub-national stats
gdl_raw <- read_csv("data-raw/covariates/GDL-AreaData400 (1).csv")

## Twitters users -----

# Twitter users by country, Hootsuite, January 2020
hootsuite_raw <- read_excel("data-raw/covariates/twitter_hootsuite.xlsx", skip = 1)

# GADM boundaries -----
## National
gadm_nat_raw <- list.files(pattern = "0_sf\\.rds", recursive = TRUE) %>%
  map_df(~readRDS(.))

gadm_sub_raw <- c("data-raw/shapefiles/gadm36_AFG_1_sf.rds",
                  "data-raw/shapefiles/gadm36_NGA_1_sf.rds",
                  "data-raw/shapefiles/gadm36_GEO_2_sf.rds",
                  "data-raw/shapefiles/gadm36_MEX_1_sf.rds",
                  "data-raw/shapefiles/gadm36_ZWE_1_sf.rds"
                  ) %>%
  map_df(~readRDS(.))

# Election data ------

## Nigeria presidential elections ----
## from Stears
stears_19_raw <- fromJSON("data-raw/election/Nigeria/nigeria2019.json")
stears_15_raw <- fromJSON("data-raw/election/Nigeria/nigeria2015.json")

# Look-up for Nigeria state abbreviations
nga_state_abbrev <- read_csv("data-raw/election/Nigeria/nigeria_state_abbreviations.csv", skip = 1)

## Afghanistan presidential -----
afg_19_raw <- read_csv("data-raw/election/Afghanistan/2019-Presidential-national-presidential.csv")
afg_14_raw <- read_csv("data-raw/election/Afghanistan/2014-Presidential-national-presidential.csv")
afg_09_raw <- read_csv("data-raw/election/Afghanistan/2009-Presidential-national-presidential.csv")

## Georgia presidential ----
geo_08_raw <- read_csv("data-raw/election/Georgia/Georgia_Election_Data_2008_Presidential_EN_CSV.csv")
geo_13_raw <- read_csv("data-raw/election/Georgia/Georgia_Election_Data_2013_Presidential_EN_CSV.csv")

## Mexico presidential ----
mex_18_raw <- read_csv("data-raw/election/Mexico/presidencia_2018.csv", skip = 5)
mex_18_candidates_raw <- read_csv("data-raw/election/Mexico/presidencia_candidaturas_2018.csv")
mex_12_raw <- read_csv("data-raw/election/Mexico/consulta2012.csv")

## Zimbabwe presidential ----
zwe_13_raw <- read_csv("data-raw/election/Zimbabwe/2013/2013_national_presidential_results.csv")
zwe_18_raw <- read_csv("data-raw/election/Zimbabwe/2018/zimbabwe_18_wiki.csv")

# Polling data ----
## Ad hoc from various sources -----
polling_adhoc_raw <- read_excel("data-raw/polling/polling_manual.xls", sheet = "adhoc")

## Country sheets -----
polling_mex_raw <- read_excel("data-raw/polling/polling_manual.xls", sheet = "mexico")

## Afrobarometer surveys -----
# https://afrobarometer.org/data/merged-data
afro_r7_raw <- haven::read_sav("data-raw/polling/r7_merged_data_34ctry.release.sav")
afro_r6_raw <- haven::read_sav("data-raw/polling/merged_r6_data_2016_36countries2.sav")
afro_r5_raw <- haven::read_sav("data-raw/polling/merged-round-5-data-34-countries-2011-2013-last-update-july-2015.sav")

# Sentiment lexicons ----
## from textdata package
afinn <- get_sentiments("afinn")
bing <- get_sentiments("bing")
nrc <- get_sentiments("nrc")

# Other ----
## REIGN leader data ----
reign_raw <- read_csv("data-raw/other/REIGN_2021_2.csv")

## Leader name look-up -----
## Used to match names between REIGN and candidates objects
name_lookup <- read_csv("data-raw/other/name_lookup.csv")

