###### Format data for getting Tweets

# Format REIGN data -----
## Leadership and term variables
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

# Format election candidates data ------
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

# Format GADM boundary data ------
# Only includes certain countries we'd picked out
gadm <- gadm_1_raw %>%
  clean_names() %>%
  transmute(country = as.character(name_0),
            geometry,
            #gadm_id = row_number()
  )

# Simplify country boundaries for plotting
gadm_simp <- gadm %>%
  st_simplify(., dTolerance = 0.1)

# Create smallest-possible circles ------
# For loop to find circle for each country
circs <- c()

for (i in 1:nrow(gadm)){
  
  # Turn to owin
  owin <- gadm[i,] %>%
    st_transform(3857) %>% # need planar projection
    as_Spatial() %>%
    as.owin()
  
  # Create smallest-possible circle
  circ <- boundingcircle(owin) %>%
    st_as_sf() %>%
    st_set_crs(3857)
  
  # Add to vector
  circs[i] <- circ$geom
  
}

# Add smallest-possible circles (spc) to dataframe
small_circs <- gadm %>%
  as.data.frame() %>%
  mutate(id = row_number()) %>%
  select(-geometry) %>%
  st_set_geometry(., st_sfc(circs, crs = 3857)) %>%
  st_transform(4326)

# Find centre and calculate radius
small_centres <- small_circs %>%
  st_transform(., 27700) %>% # convert to British National Grid to work in meters, required for calculating radius
  st_centroid()

# Convert to linestring before calculating distance
small_lines <- small_circs %>%
  st_transform(., 27700) %>% # convert to British National Grid to work in meters, required for the scraping radius
  st_cast(to = "MULTILINESTRING")

# Calculate radius in metres
small_circs$radius <- st_distance(small_lines$geometry, small_centres$geometry,
                                  by_element = TRUE,
                                  which = "Euclidean"
)

# Get coordinates of centres in longitude and latitude before joining
small_centres_4326 <- small_centres %>%
  st_transform(4326) %>%
  st_coordinates() %>%
  as_tibble() %>%
  transmute(x = X,
            y = Y,
            id = row_number())

# Add centre points to dataset
country_geocode <- small_circs %>%
  left_join(small_centres_4326, by = "id", keep = FALSE) %>%
  as_tibble() %>%
  transmute(country, geocode = paste0(x, ",", y, ",", radius/1000, "km"))

# Join data -----
# Takes a while to join
scrape_data <- names_scrape %>%
  left_join(country_geocode, by = "country") %>%
  arrange(name, date)
