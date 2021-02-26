###### Format data for getting Tweets

###### Format REIGN data with leadership and term variables
leaders <- reign_raw %>%
  clean_names() %>%
  select(country, name = leader, year, month) %>%
  filter(country %in% c("Nigeria", "Afghanistan")) %>% # filter countries
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

###### Format election candidates data
## Choose how long back you want to scrape data for losing election candidates
candidates_scrape <- candidates %>%
  ungroup() %>%
  mutate(elex_start = (elex_date - months(2)) %>% floor_date(., unit = "month") # eg beginning of month two months ago
  ) %>%
  select(country, name, start = elex_start, end = elex_date)

##### Bind leaders with candidates and choose scraping frequency
names_scrape <- leaders %>%
  select(-term_n) %>%
  mutate(type = "leader") %>%
  bind_rows(candidates_scrape) %>%
  mutate(type = if_else(is.na(type), "candidate", type)) %>%
  arrange(country, end) %>%
  mutate(name = case_when(name %in% c("Hamed Karzai", "Hamid Karzai") ~ "Karzai",
                          name %in% c("Dr. Abdullah Abdullah", "Abdullah Abdullah") ~ "Abdullah",
                          name %in% c("Dr. Mohammad Ashraf Ghani Ahmadzai", "Mohammad Ashraf Ghani", "Ashraf Ghani") ~ "Ghani",
                          name == "Muhammadu Buhari" ~ "Buhari",
                          name %in% c("Goodluck Jonathan") ~ "Goodluck Jonathan",
                          name %in% c("Atiku Abudakar") ~ "Abudakar",
                          TRUE ~ name)
  ) %>%
  rowwise() %>%
  # choose scraping frequency, day, week, or a number of days
  ## Floor start and ceiling end of term period
  mutate(date = list(seq.Date(floor_date(start, "month"), ceiling_date(end, "month"), by = 7))) %>%
  tidyr::unnest(date) %>%
  transmute(country = case_when(country == "USA" ~ "United States",
                                TRUE ~ country),
            name,
            date = date, # scrape start time (since)
            date_end = date + days(6), # scrape end time (to)
  ) %>%
  filter(date >= as.Date("2006-07-15")) # when Twitter full version went live

head(names_scrape)

###### Format GADM boundary data
# Only includes certain countries we'd picked out
gadm_1 <- gadm_1_raw %>%
  clean_names() %>%
  transmute(country = as.character(name_0),
            geometry,
            #gadm_id = row_number()
  )

# Simplify and transform to BNG for plotting
gadm_1_simp <- gadm_1 %>%
  st_transform(27700) %>%
  st_simplify(., dTolerance = 1000)

###### Join data
# Takes a while to join
scrape_data <- names_scrape %>%
  left_join(gadm_1_simp, by = "country") %>%
  #filter(!is.na(geocode)) %>%
  arrange(name, date)
