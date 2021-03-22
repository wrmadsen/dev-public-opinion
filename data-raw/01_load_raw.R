###### Load data

# English speakers ----
# English speakers data from the UN
un_lang_raw <- read_csv("data-raw/other/UNdata_Export_20210203_194758725.csv")

# English speakers data pasted from Ethnologue
ethno_raw <- read_excel("data-raw/other/ethnologue_english.xlsx")

# English speakers data from Wikipedia
wiki_raw <- read_excel("data-raw/other/english_wiki.xlsx", skip = 1)

# Indices ----

# Corruption perception index
cpi_raw <- read_excel("data-raw/other/CPI2020_GlobalTablesTS_210125.xlsx",
                      sheet = "CPI Timeseries 2012 - 2020",
                      skip = 2)

# WGI data, voice and accountability index
wgi_raw <- read_excel("data-raw/other/wgidataset.xlsx", sheet = "VoiceandAccountability", skip = 12)

# UN and World Bank ----

# UN population estimates
## https://population.un.org/wpp/Download/Standard/CSV/
pop_raw <- read_csv("data-raw/other/WPP2019_TotalPopulationBySex.csv")

# GDP PPP from World Bank
## https://data.worldbank.org/indicator/NY.GDP.MKTP.PP.KD
gdp_ppp_raw <- read_csv("data-raw/other/API_NY.GDP.MKTP.PP.KD_DS2_en_csv_v2_1928416.csv", skip = 3)

# Twitters users -----

# Twitter users by country, Hootsuite, January 2020
hootsuite_raw <- read_excel("data-raw/other/twitter_hootsuite.xlsx", skip = 1)

# Load leader data from REIGN
reign_raw <- read_csv("data-raw/other/REIGN_2021_2.csv")

# GADM boundaries -----
## National
gadm_0_raw <- c("https://biogeo.ucdavis.edu/data/gadm3.6/Rsf/gadm36_NGA_0_sf.rds",
                "https://biogeo.ucdavis.edu/data/gadm3.6/Rsf/gadm36_AFG_0_sf.rds") %>%
  map_df(~readRDS(url(.)))

## Subnational
gadm_1_raw <- c("https://biogeo.ucdavis.edu/data/gadm3.6/Rsf/gadm36_NGA_1_sf.rds",
                "https://biogeo.ucdavis.edu/data/gadm3.6/Rsf/gadm36_AFG_1_sf.rds") %>%
  map_df(~readRDS(url(.)))

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

# Sentiment lexicons ----
## from textdata package
afinn <- get_sentiments("afinn")
bing <- get_sentiments("bing")
nrc <- get_sentiments("nrc")

# Common name look-up -----
## Used to match names between REIGN and candidates objects
name_lookup <- read_csv("data-raw/other/name_lookup.csv")

# Not currently used -----

# # Load Global Data Lab data
# ## https://globaldatalab.org/areadata-raw/download_files/
# gdl_raw <- read_csv("data-raw/other/GDL-AreaData390 (1).csv")
#
# # Load cities data
# # Africapolis
# ## https://africapolis.org/data
# afri_polis_raw <- read_excel("data-raw/other/Africapolis_agglomeration_2015.xlsx", skip = 15)
#
# # World Cities shapefiles from ArcGIS, long and lat
# cities_raw <- st_read("data-raw/other/World_Cities-shp/World_Cities.shp")
#
# # GPW data
# # Load GPW4 Admin Unit data
# ## https://sedac.ciesin.columbia.edu/data-raw/set/gpw-v4-admin-unit-center-points-population-estimates-rev11
# gpw_raw <- list.files(pattern = "gpw_v4_admin_unit.+\\.shp", recursive = TRUE) %>%
#   map_df(~st_read(.))
