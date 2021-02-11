###### Load data

###### Load supplementary data
# English speakers data from the UN
un_lang_raw <- read_csv("data/raw/UNdata_Export_20210203_194758725.csv")

# English speakers data pasted from Ethnologue
ethno_raw <- read_excel("data/raw/ethnologue_english.xlsx")

# English speakers data from Wikipedia
wiki_raw <- read_excel("data/raw/english_wiki.xlsx", skip = 1)

# Corruption perception index
cpi_raw <- read_excel("data/raw/CPI2020_GlobalTablesTS_210125.xlsx",
                      sheet = "CPI Timeseries 2012 - 2020",
                      skip = 2)

# WGI data
wgi_raw <- read_excel("data/raw/wgidataset.xlsx", sheet = "VoiceandAccountability", skip = 12)

# UN population estimates
## https://population.un.org/wpp/Download/Standard/CSV/
pop_raw <- read_csv("data/raw/WPP2019_TotalPopulationBySex.csv")

# GDP PPP from World Bank
## https://data.worldbank.org/indicator/NY.GDP.MKTP.PP.KD
gdp_ppp_raw <- read_csv("data/raw/API_NY.GDP.MKTP.PP.KD_DS2_en_csv_v2_1928416.csv", skip = 3)

# Twitter users by country, Hootsuite, January 2020
hootsuite_raw <- read_excel("data/raw/twitter_hootsuite.xlsx", skip = 1)

###### Load data to use in collecting Tweets
# Load leader data from REIGN
reign_raw <- read_csv("data/raw/REIGN_2021_2.csv")

###### Load subnational data

# Load Global Data Lab data
## https://globaldatalab.org/areadata/download_files/
gdl_raw <- read_csv("data/raw/GDL-AreaData390 (1).csv")

# Subnational infant mortality
## https://sedac.ciesin.columbia.edu/data/set/povmap-global-subnational-infant-mortality-rates-v2/data-download

###### Load spatial data

# GDL shapefiles
# save(gdl_shp_raw, file = "data/gdl_shp_raw.rdata") # save as rdata to speed up loading after first time
#load("data/gdl_shp_raw.rdata")

# Africapolis
## https://africapolis.org/data
afri_polis_raw <- read_excel("data/raw/Africapolis_agglomeration_2015.xlsx", skip = 15)

# Load World Bank boundaries
#wb_0_raw <- st_read("data/WB_Boundaries_GeoJSON_highres/WB_countries_Admin0.geojson")

# Eurostat
#gaul1_raw <- st_read("data/gaul1_asap/gaul1_asap.shp")

# GPW data
# Load GPW4 Admin Unit data
# gpw_raw <- list.files(pattern = "gpw_v4_admin_unit.+\\.csv", recursive = TRUE) %>%
#   map_df(~read_csv(.))

# Load GPW4 Admin Unit shapefiles
## Nigeria
#nga_shp_raw <- st_read("data/gpw_admin/gpw-v4-admin-unit-center-points-population-estimates-rev11_nga_shp/gpw_v4_admin_unit_center_points_population_estimates_rev11_nga.shp")

# Load GPW4 Population raster count, 15 minute resolution (30 km), raster data
gpw_30_raw <- read_stars("data/gpw_pop/gpw-v4-population-count-rev11_2020_15_min_tif/gpw_v4_population_count_rev11_2020_15_min.tif")

# Natural Earth cultural country boundaries
#ne_raw <- st_read("data/ne_50m_admin_0_countries/ne_50m_admin_0_countries.shp")

# OCHA boundary data
ocha_raw <- st_read("data/nga_adm_osgof_20190417/nga_admbnda_adm1_osgof_20190417.shp")

# GADM subnational admin boundaries
gadm_1_raw <- list.files(pattern="gadm36.+1\\.shp$", full.names = TRUE, recursive = TRUE) %>%
  map_df(~st_read(.))


