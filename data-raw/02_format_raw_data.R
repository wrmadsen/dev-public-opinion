# Format data

# This will serve to decide and describe the countries in focus

# Clean supplementary -----
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

# Bind supplementary ------
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

# Format GADM boundary data ------

## National boundaries ----
boundaries_national <- gadm_nat_raw %>%
  clean_names() %>%
  transmute(country = as.character(name_0),
            geometry
  )

## Sub-national boundaries ----
boundaries_subnational <- gadm_sub_raw %>%
  clean_names() %>%
  transmute(country = as.character(name_0),
            region_1 = as.character(name_1),
            engtype_1,
            region_2 = as.character(name_2),
            engtype_2,
            geometry
  ) %>%
  # correct typos or adapt before joining with other objects, e.g. election data
  mutate(region_1 = case_when(region_1 == "Nassarawa" ~ "Nasarawa",
                              TRUE ~ region_1))

# Vector of subnational boundary names
subnational_names <- boundaries_subnational %>%
  as.data.frame() %>%
  select(-geometry)

# Format REIGN ----
## Leadership and term variables
reign <- reign_raw %>%
  clean_names() %>%
  select(country, name = leader, year, month) %>%
  # filter countries
  filter(country %in% c("Nigeria", "Zimbabwe", "Georgia", "Mexico", "Afghanistan")) %>%
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
  # count terms per leader - NEED TO ADJUST FOR NAMES, e.g. Løkke, father-son?
  mutate(term_n = paste0("term ", 1:n())) %>%
  ungroup() %>%
  pivot_wider(names_from = date_type, values_from = date) %>%
  mutate(term_start = if_else(is.na(term_start), term_end, term_start),
  ) %>%
  # match between reign and candidates objects
  left_join(., name_lookup, by = c("name" = "from")) %>%
  mutate(common = if_else(is.na(common), name, common)) %>%
  select(-name) %>%
  rename(start = term_start, end = term_end, name = common) %>%
  # drop NA names, i.e. countries or leaders not included in look-up
  filter(!is.na(name))

# Format election results -------

## NGA Nigeria presidential election ----
# from inspecting Stears website
## Initial formatting
nga_p_19 <- stears_19_raw %>%
  as_tibble() %>%
  select(president) %>%
  unnest(cols = c(president)) %>%
  unnest(cols = c(president)) %>%
  filter(!is.na(candidate))

nga_p_15 <- stears_15_raw[1] %>%
  as_tibble() %>%
  unnest(cols = c(stateData))

# missing 2011 election, have attempted to contact INEC (Independent National Electoral Commission, Nigeria)

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

# Add state names from abbreviations by joining look-up table
nga_pres <- nga_pres %>%
  full_join(., nga_state_abbrev %>% select(-official_abbrev),
            by = c("state" = "stears_abbrev")) %>%
  select(elex_date, country, region_1 = state_name, name, votes)

# Add national count rows to Nigeria (to match with Tweets without points)
nga_pres <- nga_pres %>%
  mutate(region_1 = "National") %>%
  group_by(elex_date, country, region_1, name) %>%
  summarise(votes = sum(votes)) %>%
  ungroup() %>%
  bind_rows(nga_pres)

## AFG Afghanistan president data ----
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

# Afghanistan, summarise nationally to match with Tweets with no points
# Seems that most if not all Afghan tweets don't carry any points data (a Twitter policy?)
afg_pres <- bind_rows(afg_09, afg_14) %>%
  bind_rows(afg_19) %>%
  filter(!name %in% c("votes")) %>%
  # add election date, first day if several (but second round)
  mutate(elex_date = case_when(year == 2009 ~ as.Date("2009-08-20"),
                               year == 2014 ~ as.Date("2014-06-14"), # second round
                               year == 2019 ~ as.Date("2019-09-28")
  ),
  country = "Afghanistan"
  ) %>%
  transmute(elex_date, country, region_1 = "National", name, votes) %>%
  group_by(elex_date, country, region_1, name) %>%
  summarise(votes = sum(votes)) %>%
  ungroup()

## GEO Georgia presidential elections ----
geo_08 <- geo_08_raw %>%
  pivot_longer(cols = c(6:12), names_to = "name", values_to = "votes_share") %>%
  clean_names() %>%
  filter(map_level %in% c("Country", "District")) %>%
  select(map_level, country_name, name, votes_share, votes_total = total_voter_turnout_number) %>%
  mutate(elex_date = as.Date("2008-01-05"),
         votes_share = as.double(votes_share))

geo_13 <- geo_13_raw %>%
  pivot_longer(cols = c(6:28), names_to = "name", values_to = "votes_share") %>%
  clean_names() %>%
  filter(map_level %in% c("Country", "District")) %>%
  select(map_level, country_name, name, votes_share, votes_total = total_voter_turnout_number) %>%
  mutate(elex_date = as.Date("2013-10-27"))

geo_pres <- bind_rows(geo_08, geo_13) %>%
  transmute(elex_date,
            country = "Georgia",
            region_2 = case_when(map_level == "Country" ~ "National",
                                 map_level == "District" ~ country_name),
            name,
            votes_share = votes_share/100,
            votes_total)

## MEX Mexico presidential ----
# 2012
mex_12 <- mex_12_raw %>%
  pivot_longer(cols = 5:10, names_to = "movement", values_to = "votes") %>%
  clean_names() %>%
  mutate(region_1 = name_state %>% str_to_title,
         name = case_when(
           # Peña Nieto
           movement == "COMMITMENT TO MEXICO" ~ "Pena Nieto",
           # Obrador
           movement == "PROGRESSIVE MOVEMENT" ~ "Obrador",
           # Quadria
           movement == "NEW ALLIANCE" ~ "Quadri",
           # Vazquez mota
           movement == "BREAD" ~ "Vázquez Mota",
           TRUE ~ movement)
  ) %>%
  select(region_1, name, votes, total_votes)

mex_12 <- mex_12 %>%
  group_by(region_1, name) %>%
  summarise(votes = sum(votes, na.rm = TRUE)) %>%
  mutate(elex_date = as.Date("2012-07-01"))

# 2018
mex_18 <- mex_18_raw %>%
  clean_names() %>%
  pivot_longer(cols = 13:35, names_to = "party", values_to = "votes") %>%
  transmute(region_1 = str_to_title(nombre_estado),
            party, votes,
            total_votes = total_votos_calculados) %>%
  mutate(name = case_when(
    # Anaya cortes
    party %in% c("pan", "prd", "mc",
                 "pan_prd_mc", "pan_prd",
                 "pan_mc",
                 "prd_mc",
                 "movimiento_ciudadano") ~ "Anaya",
    # Lopez obrador
    party %in% c("pt", "morena", "pes",
                 "pt_morena_pes", "pt_morena",
                 "pt_pes", "encuentro_social",
                 "morena_pes") ~ "Obrador",
    # Meade kuribre
    party %in% c("pri", "pvem", "nueva_alianza",
                 "pri_pvem_na", "pri_pvem",
                 "pri_na",
                 "pvem_na") ~ "Meade",
    TRUE ~ "Other")
  )

mex_18 <- mex_18 %>%
  group_by(region_1, name) %>%
  summarise(votes = sum(votes, na.rm = TRUE)) %>%
  mutate(elex_date = as.Date("2018-07-01"))

# Bind Mexican years
mex_pres <- bind_rows(mex_12, mex_18) %>%
  # fix region names to match GDL, old to new with recode()
  mutate(region_1 = recode(region_1,
                           "Nuevo Le”N" = "Nuevo León",
                           "San Luis Potosi" = "San Luis Potosí",
                           "San Luis Potosõ" = "San Luis Potosí")) %>%
  mutate(country = "Mexico") %>%
  ungroup()

# Add national level
mex_pres <- mex_pres %>%
  mutate(region_1 = "National") %>%
  group_by(elex_date, country, region_1, name) %>%
  summarise(votes = sum(votes, na.rm = TRUE)) %>%
  ungroup() %>%
  bind_rows(mex_pres)

## ZWE Zimbabwe presidential ----
zwe_13 <- zwe_13_raw %>%
  pivot_longer(2:ncol(.), names_to = "name", values_to = "votes") %>%
  rename(region_1 = Province) %>%
  mutate(elex_date = as.Date("2013-07-31")) %>%
  filter(!name %in% c("Votes Rejected",
                      "Total Votes Cast"))

zwe_18 <- zwe_18_raw %>%
  pivot_longer(2:8, names_to = "name", values_to = "votes") %>%
  rename(region_1 = Province) %>%
  select(-`Valid votes`) %>%
  mutate(elex_date = as.Date("2018-07-3"))

# Bind Zimbabwe
zwe_pres <- bind_rows(zwe_13, zwe_18) %>%
  filter(!region_1 %in% c("Total", "Percent")) %>%
  mutate(country = "Zimbabwe",
         name = case_when(name == "Mugabe Robert Gabriel (ZANU PF)" ~ "Mugabe",
                          name == "Tsvangirai Morgan (MDC-T)" ~ "Tsvangirai",
                          name == "Dabengwa Dumiso (ZAPU)" ~ "Dabengwa",
                          name == "Ncube Welshman (MDC)" ~ "Ncube",
                          name == "Mukwazhe Munodei Kisinoti (ZDP)" ~ "Mukwazhe",
                          TRUE ~ name
         )

  )

zwe_pres$name %>% unique

# Add national level
zwe_pres <- zwe_pres %>%
  mutate(region_1 = "National") %>%
  group_by(elex_date, country, region_1, name) %>%
  summarise(votes = sum(votes, na.rm = TRUE)) %>%
  ungroup() %>%
  bind_rows(zwe_pres)

## Combine different countries' elections ----
# Bind countries
elex_combined <- bind_rows(afg_pres, nga_pres) %>%
  bind_rows(., geo_pres) %>% # Georgia
  bind_rows(mex_pres) %>% # Mexico
  bind_rows(zwe_pres) %>% # Zimbabwe
  left_join(., name_lookup, by = c("name" = "from")) %>%
  mutate(name = if_else(is.na(common), name, common)) %>%
  select(-common) %>%
  mutate(region_2 = if_else(is.na(region_2), region_1, region_2))

# Format master election object
elex_master <- elex_combined %>%
  group_by(elex_date, country, region_1, region_2) %>%
  mutate(votes_total = sum(votes)) %>%
  ungroup() %>%
  # add votes share if not already there
  # votes shares before for Georgia
  mutate(votes_share = if_else(is.na(votes_share), votes/votes_total, votes_share)) %>%
  mutate(region_1 = if_else(is.na(region_1), region_2, region_1),
         region_2 = if_else(is.na(region_2), region_1, region_2)
  )

# Subset two candidates per election with most votes for Tweet collection
candidates <- elex_master %>%
  filter(region_1 == "National" | region_2 == "National") %>%
  filter(!name %in% c("Other", "other")) %>%
  group_by(elex_date, country, region_1) %>%
  #mutate(winner = if_else(votes_share = max(votes_share) == ))
  slice_max(votes_share, n = 2) %>%
  ungroup() %>%
  arrange(country, elex_date)

## Unique candidates
candidates %>% distinct(country, elex_date, name) #%>% filter(country == "Georgia")

# Format polling data -----

## Ad hoc polling ----
polling_adhoc <- polling_adhoc_raw %>%
  mutate(date = as.Date(date)) %>%
  select(-source)

## Country sheets ----
polling_mex <- polling_mex_raw %>%
  mutate(date = as.Date(date, "%d-%m-%y")) %>%
  select(-company, -remarks) %>%
  pivot_longer(cols = 2:6, names_to = "leader", values_to = "votes_share") %>%
  mutate(country = "Mexico",
         region_1 = "National",
         region_2 = "National",
         # old to new leader names
         leader = recode(leader,
                         "obrador" = "Obrador",
                         "anaya" = "Anaya",
                         "nieto" = "Pena Nieto",
                         "quadri" = "Quadri",
                         "vazquez" = "Vázquez Mota")
  ) %>%
  filter(!is.na(votes_share))

## Combine country sheets and ad hoc ----
polling_master <- bind_rows(polling_adhoc, polling_mex)

polling_master %>% distinct(leader)

# ## Afrobarometer rounds ----
# # q99 Vote for which party in r7
# # q40 is  How much fear political intimidation or violence
# afro_r7 <- afro_r7_raw %>%
#   mutate(across(where(is.labelled),
#                 ~as_factor(., levels = "labels", ordered = TRUE) %>% trimws #%>% str_squish %>% tolower
#   )
#   )
#
# afro_r7 <- afro_r7 %>%
#   clean_names() %>%
#   select(country, region, q99, intimidation = q40, dateintr, withinwt)
#
# # q99 is Vote for which party in r6
# # q49 is How much fear political intimidation or violence
# afro_r6 <- afro_r6_raw %>%
#   mutate(across(where(is.labelled),
#                 ~as_factor(., levels = "labels", ordered = TRUE) %>% trimws #%>% str_squish %>% tolower
#   )
#   )
#
# afro_r6 <- afro_r6 %>%
#   clean_names() %>%
#   select(country, region, q99, intimidation = q49, dateintr, withinwt)
#
#
# # q54 is How much fear political intimidation or violence
# # q99 is Vote for which party in round 5
# afro_r5 <- afro_r5_raw %>%
#   mutate(across(where(is.labelled),
#                 ~as_factor(., levels = "labels", ordered = TRUE) %>% trimws #%>% str_squish %>% tolower
#   )
#   )
#
# afro_r5 <- afro_r5 %>%
#   clean_names() %>%
#   select(country, region, q99, intimidation = q54, dateintr, withinwt)
#
# # Bind Afrobaro rounds
# afro_all <- bind_rows(afro_r7, afro_r6) %>%
#   bind_rows(afro_r5) %>%
#   filter(country %in% elex_master$country) %>%
#   rename(date = dateintr,
#          vote = q99,
#          weight = withinwt) %>%
#   # pivot longer
#   pivot_longer(cols = c(vote, intimidation)) %>%
#   mutate(value = str_remove_all(value, "'|’")) %>%
#   # old to new, party to leader
#   mutate(value = case_when(
#     # Goodluck Jonathan
#     value %in% c("Peoples Democratic Party (PDP)"
#     ) & year(date) < 2016 ~ "Goodluck Jonathan",
#     # Atiku
#     value %in% c("Peoples Democratic Party (PDP)"
#     ) & year(date) > 2015 ~ "Atiku",
#     # Buhari
#     # Parties that were merged into APC as well
#     value %in% c("All Progressive Congress (APC)",
#                  "All Progressive Congres (APC)",
#                  "Action Congress of Nigeria (ACN)",
#                  "All Nigeria Peoples Party (ANPP)",
#                  "Conscience Peoples Congress (CPC)",
#                  "All Peoples Party (APP)",
#                  "Advanced Congress of Democrats (ACD)",
#                  "Alliance for Democracy (AD)"
#     )  ~ "Buhari",
#     TRUE ~ value)
#   )
#
# afro_all %>% distinct(country, year(date))
#
# afro_share <- afro_all %>%
#   mutate(month = floor_date(date, "month")) %>%
#   # calculate number of respondents
#   group_by(country, region, month, name, value, weight) %>%
#   summarise(n = n()) %>%
#   # find share
#   group_by(country, region, month, name, weight) %>%
#   mutate(share = n/sum(n)) %>%
#   ungroup()
#
# afro_share %>% distinct(country, month)
#
# # Find weighted mean
# afro_weighted <- afro_share %>%
#   group_by(country, region, month, name, value) %>%
#   summarise(share = weighted.mean(share, weight = weight),
#             n = n()) %>%
#   ungroup() %>%
#   arrange(country, region, month)
#
# afro_weighted %>%
#   filter(name == "vote") %>%
#   group_by(country, value) %>%
#   summarise(n = sum(n)) %>%
#   arrange(-n) %>% view
#   slice_max(share, n = 3) %>%
#   ungroup() %>%
#   distinct(country, value)

# Format GDL ----
names(gdl_raw)

gdl <- gdl_raw %>%
  filter(level %in% c("Subnat", "National")) %>%
  mutate(region = if_else(region == "Total", "National", region)) %>%
  # subset countries included in election dataset
  filter(country %in% unique(elex_master$country)) %>%
  select(country, region, year,
         eye, popshare, phone, cellphone) %>%
  arrange(country, region, year)

## Create GDL to GADM region look-up ------
# Below we test ad hoc which are missing - I then update recode() function
gdl_to_gadm_regions <- gdl %>%
  distinct(country, region) %>%
  mutate(gdl_region = region) %>%
  mutate(new = str_replace_all(gdl_region, "\\(|\\)", "")) %>%
  separate(new, into = letters[seq(1, 10)], sep = "([, ? ])") %>%
  pivot_longer(cols = c(region, letters[seq(1, 10)]), values_to = "gadm_region") %>%
  select(-name) %>%
  filter(!is.na(gadm_region)) %>%
  # gdl (old) to gadm (new) with recode
  mutate(gadm_region = recode(gadm_region,
                              "Abuja FCT" = "Federal Capital Territory",
                              "Helmand" = "Hilmand",
                              "Daikundi" = "Daykundi",
                              "Herat" = "Hirat",
                              "Nooristan" = "Nuristan",
                              "Panjsher" = "Panjshir",
                              "Sar-e-Pul" = "Sari Pul",
                              "Nassarawa" = "Nasarawa",
                              "Zamfora" = "Zamfara",
                              "Mexico" = "México",
                              "Michoacan" = "Michoacán",
                              "Nuevo Leon" = "Nuevo León",
                              "Queretaro" = "Querétaro",
                              "Potosi" = "San Luis Potosí", # was split up by separate()
                              "Yucatan" = "Yucatán",
                              "Matebeleland North" = "Matabeleland North",
                              "Matebeleland South" = "Matabeleland South",
                              "Racha-Lochkhumi" = "Racha-Lechkhumi-Kvemo Svaneti", # split up because of space
                              "Samegrelo-Zemo Svateni" = "Samegrelo-Zemo Svaneti"
  )) %>%
  distinct(gdl_region, gadm_region) %>%
  # remove gadm_names with parantheses
  filter(!str_detect(gadm_region, "\\(|\\)")) %>%
  # remove if name doesn't exist in GADM
  filter(gadm_region %in% subnational_names$region_1 | gadm_region %in% subnational_names$region_2)

# Check if the look-up misses any GADM names
subnational_names %>%
  pivot_longer(cols = c(region_1, region_2)) %>%
  filter(!is.na(value)) %>%
  #filter(!country == "Georgia" & !name == "region_2") %>%
  filter(name == "region_1") %>%
  filter(!value %in% gdl_to_gadm_regions$gadm_region)

## Add GADM names to GDL----
gdl_w_gadm <- gdl %>%
  left_join(.,
            gdl_to_gadm_regions,
            by = c("region" = "gdl_region")) %>%
  # Fix that GDL national observations weren't matched
  mutate(gadm_region = if_else(region == "National", "National", gadm_region)) %>%
  select(-region) %>%
  select(country, gadm_region, year, everything()) %>%
  arrange(country, gadm_region, year) %>%
  distinct()

# Choose one observation when a region appears more than once in a year
# Choose that which is smallest/lowest pop share, implying more precise data
gdl_w_gadm <- gdl_w_gadm %>%
  group_by(country, gadm_region, year) %>%
  slice_min(popshare, n = 1) %>%
  ungroup()

## Fill missing years with linear interpolation -----
gdl_interpo <- gdl_w_gadm %>%
  group_by(country, gadm_region) %>%
  complete(year = 2006:2021) %>% # Twitter founded in 2006
  arrange(country, gadm_region, year) %>%
  # linear interpolation for missing years
  # extrapolate with rule = 2: the value at the closest data extreme is used
  mutate(across(c(eye, popshare, cellphone, phone), ~zoo::na.approx(., na.rm = FALSE, rule = 2))) %>%
  ungroup()


# Create covariates master -----

## Bind polling and election results -----

# Check that polling names all match a leader name in election data
unique(polling_master$leader) %in% unique(elex_master$name)

targets_master <- bind_rows(polling_master %>%
                                   rename(name = leader) %>%
                                   mutate(type = "poll"),
                                 elex_master %>%
                                   rename(date = elex_date) %>%
                                   mutate(type = "election")
                                   ) %>%
  rename(date_target = date) %>%
  arrange(date_target) %>%
  select(-c(votes, votes_total))


## Add GDL statistics -----
# covariates <- polling_elex_master %>%
#   mutate(id = row_number(),
#          year = year(date)) %>%
#   # Join by region_2 because it is equal to region_1
#   # if the country did not have that level to begin with
#   left_join(gdl_interpo,
#             by = c("year", "country", "region_2" = "gadm_region"))
#
# # Check if any regions appear twice in same year
# covariates %>% group_by(id) %>% filter(n() > 1) %>% distinct(region_1)
#
# # Check regions in the rows that don't match with GDL
# covariates %>% filter(is.na(popshare) & is.na(phone)) %>% distinct(country, region_1)
#
# anti_join(polling_elex_master %>% mutate(year = year(date)),
#           gdl_interpo,
#           by = c("year", "country", "region_2" = "gadm_region")) %>%
#   distinct(country, region_1) %>% view()

# Combine sentiment lexicons ----
## Prepare afinn by stemming and finding mean value of words with same stem
afinn_stem <- afinn %>%
  mutate(stem = SnowballC::wordStem(word)) %>%
  group_by(stem) %>%
  summarise(afinn_value = max(value))

senti_lexicons <- afinn %>%
  full_join(bing %>% rename(bing_sentiment = sentiment)) %>%
  full_join(nrc %>% rename(nrc_sentiment = sentiment))

