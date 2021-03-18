###### Format data

# This will serve to decide and describe the countries in focus

## Clean supplementary -----
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
wgi <- wgi_raw
colnames(wgi) <- paste0(colnames(wgi_raw), wgi_raw[1, ])
wgi <- wgi %>%
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

## Bind supplementary ------
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

## Format region data ------

## Format GADM boundary data ------

### National boundaries
# Only includes certain countries we'd picked out
gadm <- gadm_1_raw %>%
  clean_names() %>%
  transmute(country = as.character(name_0),
            geometry,
            #gadm_id = row_number()
  )

# GDL data
gdl <- gdl_raw %>%
  clean_names()

### Subnational boundaries



## Format election data -------

## Format reign ----
## Leadership and term variables
reign <- reign_raw %>%
  clean_names() %>%
  select(country, name = leader, year, month) %>%
  # get start and end of term for each leader, need to use row_number to get last term of last country
  filter(lag(name) != name | lead(name) != name | row_number() == n()) %>%
  # note term number, several sequentially count as one
  mutate(date_type = if_else(lead(name) != name | row_number() == n(), "term_end", "term_start"),
         date = paste0(year, "-", str_pad(month, 2, "left", pad = "0"), "-01"),
         date = as.Date(date)
  ) %>%
  # drop leaders with terms that ended before 2006 (Twitter's founding)
  filter(!(year < 2006 & date_type == "term_end" | date_type == "term_start" & lead(year) < 2006)) %>%
  select(country, name, date_type, date) %>%
  group_by(country, name, date_type) %>%
  mutate(term_n = paste0("term ", 1:n())) %>% # count terms per leader - NEED TO ADJUST FOR NAMES, e.g. Løkke, father-son?
  ungroup() %>%
  pivot_wider(names_from = date_type, values_from = date) %>%
  mutate(term_start = if_else(is.na(term_start), term_end, term_start),
  ) %>%
  rename(start = term_start, end = term_end)

# Nigeria, format Presidentials election data, from inspecting Stears website
## Initial formatting
nga_p_19 <- stears_19_raw %>%
  as_tibble() %>%
  select(president) %>%
  unnest() %>%
  unnest() %>%
  filter(!is.na(candidate))

nga_p_15 <- stears_15_raw[1] %>%
  as_tibble() %>%
  unnest()

# missing 2011 election, check INEC (Independent National Electoral Commission, Nigeria)

# Bind and save Nigerian presidential election data
nga_pres <- bind_rows(nga_p_15, nga_p_19) %>%
  rename(name = candidate) %>%
  mutate(across(c(total_votes, votes), ~gsub(",", "", .) %>% as.integer),
         year = as.integer(year),
         # election date, from Wikipedia, if held over several days, take first day
         elex_date = case_when(year == 2019 ~ as.Date("2019-02-23"),
                               year == 2015 ~ as.Date("2015-03-28")
         ),
         country = "Nigeria"
  )

## Extract top candidates for each available election to use for scraping
candidates_nga <- nga_pres %>%
  group_by(country, elex_date, name) %>%
  summarise(votes = sum(votes)) %>%
  group_by(elex_date) %>%
  slice_max(votes, n = 2)

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
  bind_rows(afg_19) %>%
  filter(!name %in% c("votes")) %>%
  # add election date, first day if several (but second round)
  mutate(elex_date = case_when(year == 2009 ~ as.Date("2009-08-20"),
                               year == 2014 ~ as.Date("2014-06-14"), # second round
                               year == 2019 ~ as.Date("2019-09-28")
  ),
  country = "Afghanistan"
  )

candidates_afg <- afg_pres %>%
  group_by(country, elex_date, name) %>%
  summarise(votes = sum(votes)) %>%
  group_by(elex_date) %>%
  slice_max(votes, n = 2)

# Bind candidates data for scraping
candidates <- candidates_nga %>%
  bind_rows(candidates_afg) %>%
  ungroup() %>%
  select(-votes)

## Unique candidates
candidates$name %>% unique()

# Combine sentiment lexicons
senti_lexicons <- afinn %>%
  full_join(bing %>% rename(bing_sentiment = sentiment)) %>%
  full_join(nrc %>% rename(nrc_sentiment = sentiment))

# Save formatted data ----
save(supp, reign, candidates, nga_pres, afg_pres,
     gadm, senti_lexicons,
     file = "data/formatted_data.RData")


# Not currently used ----
# ###### GDL region shapefiles
# # Convert sp into sf dataframe
# gdl_sf <- st_as_sf(gdl_shp_raw)
#
# # Get centroids
# gdl_centroids <- st_centroid(gdl_sf$geometry) %>%
#   st_coordinates %>%
#   as_tibble() %>%
#   rename_with(~paste0("centroigdl_shp_rawd_", tolower(.)))
#
# # Simplify and add centroids
# gdl_simp <- gdl_sf %>%
#   mutate(geometry = st_simplify(geometry, dTolerance = 0.05)) %>%
#   bind_cols(gdl_centroids)
#
# ## Format city data -------
# # Africapolis
# afri_polis <- afri_polis_raw %>%
#   clean_names()

# Cities, ArcGIS, long and lat
# cities <- cities_raw %>%
#   st_as_sf() %>%
#   st_transform(., 4326) %>%
#   clean_names() %>%
#   arrange(cntry_name)
#
# cities %>%
#   st_cast("POINT") %>%
#   st_distance(st_centroid(cities))
#
# st_sf(cities$geometry)
