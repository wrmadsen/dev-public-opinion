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

# WGI data, voice and accountability index
wgi_raw <- read_excel("data/raw/wgidataset.xlsx", sheet = "VoiceandAccountability", skip = 12)

# UN population estimates
## https://population.un.org/wpp/Download/Standard/CSV/
pop_raw <- read_csv("data/raw/WPP2019_TotalPopulationBySex.csv")

# GDP PPP from World Bank
## https://data.worldbank.org/indicator/NY.GDP.MKTP.PP.KD
gdp_ppp_raw <- read_csv("data/raw/API_NY.GDP.MKTP.PP.KD_DS2_en_csv_v2_1928416.csv", skip = 3)

# Twitter users by country, Hootsuite, January 2020
hootsuite_raw <- read_excel("data/raw/twitter_hootsuite.xlsx", skip = 1)

# Load CLEA election data
#load("data/election/clea_lc_20201216.rdata")

###### Load data to use in collecting Tweets
# Load leader data from REIGN
reign_raw <- read_csv("data/raw/REIGN_2021_2.csv")

###### Load subnational data

# Load Global Data Lab data
## https://globaldatalab.org/areadata/download_files/
gdl_raw <- read_csv("data/raw/GDL-AreaData390 (1).csv")

# Subnational infant mortality
## https://sedac.ciesin.columbia.edu/data/set/povmap-global-subnational-infant-mortality-rates-v2/data-download


###### Load cities data
# Africapolis
## https://africapolis.org/data
afri_polis_raw <- read_excel("data/raw/Africapolis_agglomeration_2015.xlsx", skip = 15)

# World Cities shapefiles from ArcGIS, long and lat
cities_raw <- st_read("data/raw/World_Cities-shp/World_Cities.shp")

# Natural Earth urban landscan of cities
#landscan_raw <- st_read("data/ne_10m_urban_areas_landscan/ne_10m_urban_areas_landscan.shp")

# Natural Earth, populated places, points
#pop_points_raw <- st_read("data/ne_10m_populated_places/ne_10m_populated_places.shp")

# NASA night light data
#night_light_raw <- read_stars("data/BlackMarble_2016_01deg_gray_geo.tif")

# NASA HBASE, human settlement
#hbase_raw <- read_stars("data/01F_hbase_non_hbase_percentage_utm_1000m/01F_hbase_non_hbase_percentage_utm_1000m.tif")


###### Load region data
# GDL shapefiles
# save(gdl_shp_raw, file = "data/gdl_shp_raw.rdata") # save as rdata to speed up loading after first time
load("data/gdl_shp_raw.rdata")

# GPW data
# Load GPW4 Admin Unit data
gpw_raw <- list.files(pattern = "gpw_v4_admin_unit.+\\.shp", recursive = TRUE) %>%
  map_df(~st_read(.))

# Load GPW4 Admin Unit shapefiles
## Nigeria
#nga_shp_raw <- st_read("data/gpw_admin/gpw-v4-admin-unit-center-points-population-estimates-rev11_nga_shp/gpw_v4_admin_unit_center_points_population_estimates_rev11_nga.shp")

# Load GPW4 Population raster count, 15 minute resolution (30 km), raster data
#gpw_30_raw <- read_stars("data/gpw_pop/gpw-v4-population-count-rev11_2020_15_min_tif/gpw_v4_population_count_rev11_2020_15_min.tif")
#gpw_5_raw <- read_stars("data/gpw_pop/gpw-v4-population-count-adjusted-to-2015-unwpp-country-totals-rev11_2020_2pt5_min_tif/gpw_v4_population_count_adjusted_to_2015_unwpp_country_totals_rev11_2020_2pt5_min.tif")

# Natural Earth cultural country boundaries
#ne_raw <- st_read("data/ne_50m_admin_0_countries/ne_50m_admin_0_countries.shp")

# OCHA boundary data
#ocha_raw <- st_read("data/nga_adm_osgof_20190417/nga_admbnda_adm1_osgof_20190417.shp")

# GADM subnational admin boundaries
gadm_1_raw <- list.files(pattern="gadm36.+1\\.shp$", full.names = TRUE, recursive = TRUE) %>%
  map_df(~st_read(.))

###### Election data

# Nigeria presidential elections, from Stears
##
stears_19_raw <- fromJSON("data/election/nigeria2019.json")
stears_15_raw <- fromJSON("data/election/nigeria2015.json")

# Afghanistan
## 
afg_19_raw <- read_csv("data/election/2019-Presidential-national-presidential.csv")
afg_14_raw <- read_csv("data/election/2014-Presidential-national-presidential.csv")
afg_09_raw <- read_csv("data/election/2009-Presidential-national-presidential.csv")

