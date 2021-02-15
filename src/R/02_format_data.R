###### Format data

###### Format and bind supplementary data
# This will serve to decide and describe the countries in focus

###### Clean
# UN language population
## Appears to only show population by primary language
## May use rural, urban distinctions for weighting
un_lang_raw %>%
  clean_names() %>%
  filter(language %in% c("Total", "English")) %>%
  mutate(value = round(value)) %>%
  pivot_wider(names_from = language, values_from = value) %>%
  clean_names() %>%
  mutate(english_prop = english/total %>% round) %>%
  rename(country = country_or_area) %>%
  group_by(country, area, sex) %>%
  filter(year == max(year))

# Ethnologue language data, English speakers
ethno <- ethno_raw %>%
  mutate(country = if_else(grepl("Hide Details", English), gsub("Hide Details", "", English), NA_character_),
         country = if_else(English == "English", "United Kingdom", country),
         name = lag(English),
  ) %>%
  fill(country, name) %>%
  filter(lag(English) %in% c("User Population", "Location", "Language Status", "Other Comments")) %>%
  pivot_wider(names_from = name, values_from = English) %>%
  clean_names() %>%
  mutate(eng_total = gsub(" .+", "", user_population) %>% gsub(",", "", .) %>% as.integer,
         l1 = if_else(grepl("L1", user_population),
                      gsub(".+ L1 users: ", "", user_population),
                      NA_character_),
         l1_src = str_extract(l1,  "(?<=\\().+?(?=\\))"),
         l1 = sub(" .+", "", l1) %>% gsub(",", "", .) %>% as.integer,
         l1_yr = str_extract(l1_src, "\\d+") %>% as.integer,
         l2 = if_else(grepl("L2", user_population),
                      gsub(".+ L2 users: ", "", user_population),
                      NA_character_),
         l2_src = str_extract(l2,  "(?<=\\().+?(?=\\))"),
         l2 = sub(" .+", "", l2) %>% gsub(",", "", .) %>% as.integer,
         l2_yr = str_extract(l2_src, "\\d+") %>% as.integer,
         total_yr = if_else(l2 > l1, l2_yr, l1_yr),
         total_yr = if_else(is.na(total_yr), l2_yr, total_yr) %>% if_else(is.na(.), l1_yr, .),
         total_src = if_else(is.na(l1_src) & is.na(l2_src),
                             str_extract(user_population,  "(?<=\\().+?(?=\\))"),
                             NA_character_),
         total_yr = if_else(is.na(total_yr),
                            str_extract(total_src, "\\d+") %>% as.integer,
                            total_yr)
  )

## Subset key variables
ethno_sub <- ethno %>%
  select(country, eng_total, total_yr)

# English speakers Wikipedia
wiki_eng <- wiki_raw %>%
  slice(-1) %>%
  clean_names() %>%
  rename(eligible_pop = eligible_population,
         total_eng_speak = total_english_speakers,
         as_1st_lang = as_first_language,
         as_additional = as_an_additional_language) %>%
  mutate(across(c(2:5), as.integer),
         eng_prop_wiki = total_eng_speak/eligible_pop,
         country = str_trim(country),
  ) %>%
  select(country, eng_prop_wiki)

# Corruption
cpi <- cpi_raw %>%
  clean_names() %>%
  rename_with(~if_else(str_count(., "_") == 2, sub("_", "", .), .)) %>% # remove first _ for those with two
  pivot_longer(c(4:ncol(.)),
               names_to = c(".value", "year"),
               names_pattern = "(.+)_(.+)") %>%
  transmute(country, year = as.double(year), cpiscore)

# WGI, Voice and accountability
## paste the first row with the column name and assigning them as column names
colnames(wgi_raw) <- paste0(colnames(wgi_raw), wgi_raw[1, ])
wgi <- wgi_raw %>%
  rename_with(~gsub("\\.\\.\\.\\d*", "_", .)) %>%
  slice(-1) %>%
  pivot_longer(cols = c(3:ncol(.)),
               names_to = c("year", "name"),
               names_pattern = "(.+)_(.+)",
               values_to = "wgi_est"
  ) %>%
  filter(name == "Estimate") %>%
  transmute(country = `_Country/Territory`,
            year = as.integer(year),
            wgi_est = if_else(wgi_est == "#NA", as.double(NA), as.double(wgi_est))
  )

# UN population estimates
pop <- pop_raw %>%
  clean_names() %>%
  rename(country = location, year = time) %>%
  mutate(across(c(7:10), ~.*1000)) %>%
  filter(variant == "Medium") %>%
  filter(year %in% c(1989:2021)) %>%
  select(country, year, pop_total)

# GDP PPP data
gdp_ppp <- gdp_ppp_raw %>%
  pivot_longer(c(5:ncol(.)), names_to = "year", values_to = "gdp_ppp") %>%
  clean_names() %>%
  filter(gdp_ppp != "X66") %>%
  transmute(country = country_name, year = as.integer(year), gdp_ppp)

# Twitter users, January 2020
hootsuite <- hootsuite_raw %>%
  transmute(country,
            twitter_users = as.numeric(users)*1000) # thousands

###### Bind
supp <- cpi %>%
  full_join(ethno_sub, by = c("country", "year" = "total_yr")) %>%
  left_join(wiki_eng, by = "country") %>%
  left_join(pop, by = c("country", "year")) %>%
  left_join(gdp_ppp, by = c("country", "year")) %>%
  left_join(wgi, by = c("country", "year")) %>%
  left_join(hootsuite, by = c("country")) %>%
  mutate(eng_prop = eng_total/pop_total,
         gdp_ppp_pc = gdp_ppp/pop_total,
         twitter_users_pc = twitter_users/pop_total
  ) %>%
  filter(!is.na(eng_prop))

###### Format region data

# GDL data
gdl <- gdl_raw %>%
  clean_names()

###### Format region data

###### GDL region shapefiles
# Convert sp into sf dataframe
gdl_sf <- st_as_sf(gdl_shp_raw)

# Get centroids
gdl_centroids <- st_centroid(gdl_sf$geometry) %>%
  st_coordinates %>%
  as_tibble() %>%
  rename_with(~paste0("centroid_", tolower(.)))

# Simplify and add centroids
gdl_simp <- gdl_sf %>%
  mutate(geometry = st_simplify(geometry, dTolerance = 0.05)) %>%
  bind_cols(gdl_centroids)

# gdl_sf %>%
#   filter(country == "Nigeria") %>%
#   ggplot() +
#   geom_sf()

###### GPW admin unit data
gpw <- gpw_raw %>%
  clean_names() %>%
  arrange(countrynm, name1, name2, name3, name4)

filter(countrynm == "Jordan")

###### Format GADM subnational boundary data
# Only includes certain countries we'd picked out
gadm_1 <- gadm_1_raw %>%
  clean_names() %>%
  select(name_0, name_1, engtype_1, geometry)

# Drop geo to easily check names
gadm_1_df <- as.data.frame(gadm_1) %>%
  select(-geometry)

# Plot gadm against GPW admin
gpw %>%
  filter(countrynm == "Jordan") %>%
  #filter(name_1 == "Balqa") %>%
  ggplot() +
  geom_sf(aes(colour = name3), show.legend = FALSE) +
  geom_sf(data = gadm_1[gadm_1$name_0 == "Jordan",], colour = "black", fill = NA) + 
  geom_sf_label(data = gadm_1[gadm_1$name_0 == "Jordan",], aes(label = name_1)) +
  coord_sf(xlim = c(35, 37), ylim = c(31.5, 32.5), expand = FALSE) +
  NULL




###### Format city data
###### Africapolis
afri_polis <- afri_polis_raw %>%
  clean_names()

###### NE urban landscan
## mean_bb_xc and mean_bb_yc is midpoint

## Subset to only include cities within countries that are being analysed
### Join by regional boundary data
### This is for the countries and subnational regions we want to scrape

# Add buffer to make sf valid to join
landscan_buff <- st_buffer(landscan_raw, dist = 0)

# Join to subset
## Desired output 
# cities_cut <- st_join(landscan_buff, gadm_1, join = st_overlaps, largest = TRUE) %>%
#   select(name_0, name_1, engtype_1, city = name_conve, geometry) %>%
#   arrange(name_0, city)

## Join with region data and drop smaller parts of cities that overlap with other regions
## Note that the columns with population data are now not representative
cities_cut <- st_intersection(landscan_buff, gadm_1) %>%
  select(name_0, name_1, engtype_1, city = name_conve, geometry) %>%
  arrange(name_0, city) %>%
  group_by(city) %>%
  filter(st_area(geometry) == max(st_area(geometry))) # drop smallest intersections that extend into other regions

pop_points <- x
pop_points_raw %>%
  clean_names() %>%
  view

  names
  select(sov0name, name_en, pop2015, geometry)

st_intersection(pop_points, gadm_1) %>%
  view()

## Some NE cities were not located in 
gadm_1 %>%
  filter(!name_1 %in% cities_cut$name_1)

## Reset row names
#rownames(cities_int) <- NULL

## Drop split city features which crossed over into a different country
#cities

# Plot city against region boundaries, Jordan as an example, illustrating st_join()
cities_cut %>%
  filter(city == "Amman") %>%
  #filter(name_1 == "Balqa") %>%
  ggplot() +
  geom_sf(aes(fill = name_1)) +
  geom_sf(data = gadm_1[gadm_1$name_0 == "Jordan",], colour = "black", fill = NA) + 
  geom_sf_label(data = gadm_1[gadm_1$name_0 == "Jordan",], aes(label = name_1)) +
  coord_sf(xlim = c(35, 37), ylim = c(31.5, 32.5), expand = FALSE) +
  NULL

## Get points of middle of city boundaries, bbox
### Cannot use original NE bbox variables as they refer to previous, non-split city polygons
st_bbox_by_feature = function(x) {
  x = st_geometry(x)
  f <- function(y) st_as_sfc(st_bbox(y))
  do.call("c", lapply(x, f))
}

cities_cut$bbox = st_bbox_by_feature(cities_cut$geometry)

cities_cut %>%
  group_by(city) %>%
  st_bbox(geometry)

  st_as_sf(coords = c("mean_bb_xc", "mean_bb_yc"), crs = 4326) %>%
  select(name_conve, geometry)

## Get points of a corner of city boundaries, bbox
cities_corner <- cities_int %>%
  as_tibble() %>%
  st_as_sf(coords = c("min_bb_xmi", "min_bb_ymi"), crs = 4326) %>%
  select(name_conve, geometry)
  
## Find distance between points, which will be the radius to scrape Tweets within 
radius_km <- st_distance(landscan_mid$geometry, landscan_corner$geometry, by_element = TRUE)/1000 # divide to convert m to km

## Join radius to dataset


###### Cities, ArcGIS, long and lat
cities <- cities_raw %>%
  st_as_sf() %>%
  st_transform(., 4326) %>%
  clean_names() %>%
  arrange(cntry_name)

cities %>%
  st_cast("POINT") %>%
  st_distance(st_centroid(cities))

st_sf(cities$geometry)
?st_sf


###### Format GPW data

## Raster data, population count
# Export from raster to polygons
# gpw_30 <- st_as_sf(gpw_30_raw, as_points = FALSE, merge = FALSE) %>%
#   rename(pop = 1) %>%
#   st_transform(., 4326)
# 
# gpw_5 <- st_as_sf(gpw_5_raw, as_points = FALSE, merge = FALSE) %>%
#   rename(pop = 1) %>%
#   st_transform(., 4326)

# Get and bind GPW centroids
# gpw_centroids <- st_centroid(gpw_30$geometry) %>%
#   st_coordinates() %>%
#   as_tibble() %>%
#   rename_with(~paste0("centroid_", tolower(.)))

## Admin unit shapefiles
# nga_shp <- st_as_sf(nga_shp_raw) %>%
#   mutate(across(c(UN_2020_E), ~as.numeric(levels(.))[.])) # turn factor into numeric


###### Format election data

# Nigeria, format Presidentials election data, from inspecting Stears website
nga_p_19 <- stears_19_raw %>%
  as_tibble() %>%
  select(president) %>%
  unnest() %>%
  unnest() %>%
  filter(!is.na(candidate))

nga_p_15 <- stears_15_raw[1] %>%
  as_tibble() %>%
  unnest()

nga_pres <- bind_rows(nga_p_15, nga_p_19) %>%
  mutate(across(c(total_votes, votes), ~gsub(",", "", .) %>% as.integer),
         year = as.integer(year))

# Afghanistan president data
afg_19 <- afg_19_raw %>%
  rename(province = name,
         total = votes
  ) %>%
  pivot_longer(cols = c(4:ncol(.)), values_to = "votes") %>%
  mutate(year = 2019)


afg_14 <- afg_14_raw %>%
  rename(province = name,
         total = votes,
         total_population = totalPopulation
  ) %>%
  pivot_longer(cols = c(5:ncol(.)), values_to = "votes") %>%
  mutate(year = 2014)

afg_09 <- afg_09_raw %>%
  rename(province = name
  ) %>%
  pivot_longer(c(8:ncol(.)), values_to = "votes") %>%
  clean_names() %>%
  mutate(year = 2009)

afg_pres <- bind_rows(afg_09, afg_14) %>%
  bind_rows(afg_19)
