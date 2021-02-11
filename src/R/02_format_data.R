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

###### Format subnational data

# GDL data
gdl <- gdl_raw %>%
  select(country, region, level, year, popshare)

###### Format spatial data

###### GDL shapefiles
# Convert sp into sf dataframe
gdl_sf <- st_as_sf(gdl_shp_raw)

# Get centroids
gdl_centroids <- st_centroid(gdl_sf$geometry) %>%
  st_coordinates %>%
  as_tibble() %>%
  rename_with(~paste0("centroid_", .))

# Simplify and add centroids
gdl_simp <- gdl_sf %>%
  mutate(geometry = st_simplify(geometry, dTolerance = 0.05)) %>%
  bind_cols(gdl_centroids)

###### Format NE boundary data
ne <- st_as_sf(ne_raw) %>%
  clean_names() %>%
  select(admin, geometry)

###### Eurostat
gaul1 <- st_as_sf(gaul1_raw) %>%
  select(name0, name1, geometry) %>%
  arrange(name0)

###### Format GPW data

## Raster data, population count
# Export from raster to polygons
gpw_30 <- st_as_sf(gpw_30_raw, as_points = FALSE, merge = FALSE) %>%
  rename(pop = 1) %>%
  st_transform(., 4326)

# Get and bind GPW centroids
gpw_centroids <- st_centroid(gpw_30$geometry) %>%
  st_coordinates() %>%
  as_tibble() %>%
  rename_with(~paste0("centroid_", tolower(.)))

## Admin unit shapefiles
nga_shp <- st_as_sf(nga_shp_raw) %>%
  mutate(across(c(UN_2020_E), ~as.numeric(levels(.))[.])) # turn factor into numeric
