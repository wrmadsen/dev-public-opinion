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

###### GPW admin unit data
gpw <- gpw_raw %>%
  clean_names() %>%
  arrange(countrynm, name1, name2, name3, name4, name5, name6) %>%
  mutate(across(c(countrynm, name1, name2, name3, name4, name5, name6), as.character),
         across(c(countrynm, name1, name2, name3, name4, name5, name6), ~if_else(. == "NA", NA_character_, .)),
         gpw_smallest = case_when(!is.na(name6) ~ name6, # create variable with most granular GPW name
                                  !is.na(name5) ~ name5,
                                  !is.na(name4) ~ name4,
                                  !is.na(name3) ~ name3,
                                  !is.na(name2) ~ name2,
                                  !is.na(name1) ~ name1),
         gpw_id = row_number()
  ) %>%
  select(gpw_id, countrynm, gpw_smallest, name1, name2, name3, name4, name5, name6, total_a_km, un_2020_e)

###### Format GADM subnational boundary data
# Only includes certain countries we'd picked out
gadm_1 <- gadm_1_raw %>%
  clean_names() %>%
  transmute(across(c(name_0, name_1, engtype_1, name_2, engtype_2, name_3, engtype_3), as.character),
            geometry,
            gadm_id = row_number()
  )

# Simplify and transform to BNG for plotting
gadm_1_simp <- gadm_1 %>%
  st_transform(27700) %>%
  st_simplify(., dTolerance = 1000)

###### Create scraper locations object
# Join region polygons and admin points and calculate smallest distance
# Cut off to only include GPW points which are within GADM regions
scrape_regions <- st_join(gadm_1, gpw) %>%
  filter(!is.na(gpw_smallest)) %>% # drop regions with no points
  arrange(countrynm, name1, name2) %>%
  st_transform(., 27700) # British National Grid to work in meters, required for the scraping radius

###### Calculate radius per point
## https://github.com/r-spatial/sf/issues/1290
## Add GPW points to dataframe with region polygon geometry
## Ensures that points geometry are in same order as polygon region geometry

## Rename GPW points geometry before joining
gpw_bng <- gpw %>%
  st_transform(., 27700) %>% # transform to BNG
  select(-c(total_a_km, un_2020_e)) %>%
  as.data.frame() %>%
  rename(geometry_point = geometry)

## Convert to linestring before calculating distance
scrape_regions_line <- scrape_regions %>%
  st_cast(to = "MULTILINESTRING", ) %>%
  as.data.frame() %>% # convert to df to rename geometry to be able to join with points geometry
  rename(geometry_line = geometry)

## Join points and lines before finding smallest distance between the two (which is the radius for each point's circle)
### Ensures they are in correct order and match
scrape_find_radius <- left_join(scrape_regions_line, gpw_bng,
                                by = c("gpw_id", "countrynm", "gpw_smallest", "name1", "name2", "name3", "name4", "name5", "name6"))

dist_lines <- st_as_sf(scrape_find_radius$geometry_line)
dist_points <- st_as_sf(scrape_find_radius$geometry_point)

# Calculate distances, in metres
distance <- st_distance(dist_lines, dist_points,
                        by_element = TRUE,
                        which = "Euclidean"
)

scrape_find_radius$radius <- distance

# Create circle polygon showing scraping area
## Reproject to 27700 first in order to buffer in meters
#scrape_find_radius$geometry_point <- st_as_sf(scrape_find_radius$geometry_point)
scrape_points <- scrape_find_radius %>%
  mutate(radius_m = as.double(radius)) %>%
  select(-geometry_line) %>%
  rename(geometry = geometry_point) %>%
  as_tibble() %>%
  st_as_sf() %>%
  mutate(row_number = row_number())

## Add buffer to create scraper circles
scrape_circles <- scrape_points %>%
  st_buffer(., .$radius_m)

## Simplify circles for plotting
scrape_circles_simp <- st_simplify(scrape_circles, dTolerance = 1000)

## Overlapping circles does not seem to be fixable by simply checking which circles are within one another
## can instead use the extent to which they overlap to filter out

# Create main scraper locations object
## Could add code to subset number of locations used for each region
## e.g. three most populous, with largest circles, random, etc.
scrape_locations_sf <- scrape_points %>%
  st_transform(4326) %>% # transform back to 4326 to get long and lat
  mutate(x = st_coordinates(geometry)[,1],
         y = st_coordinates(geometry)[,2]
  ) %>%
  mutate(area_circle_m = st_area(scrape_circles$geometry),
         area_circle_km = as.double(area_circle_m)/1000000,
         radius_km = radius_m/1000)

names(scrape_locations_sf)

## Subset variables for join
scrape_locations_tbl <- scrape_locations_sf %>%
  as_tibble() %>%
  transmute(country = name_0,
            region = name_1,
            region_type = engtype_1,
            sub_region = if_else(is.na(name_2), name_1, name_2),
            sub_region_type = if_else(is.na(engtype_2), engtype_1, engtype_2),
            location = if_else(is.na(name_2),
                               paste0(name_1, "_", str_to_title(gpw_smallest)), # if name 2 is not available
                               paste0(name_1, "_", name_2, "_", str_to_title(gpw_smallest)) # if name 2 is available
                               ),
            location_no = as.factor(location) %>% as.numeric,
            geocode = paste0(x, ",", y, ",", radius_km, "km"),
            total_a_km,
            un_2020_e,
            area_circle_km,
            radius_km
  ) %>%
  # subset circles within each region
  group_by(country, sub_region) %>%
  slice_max(un_2020_e, n = 1) # most populous

head(scrape_locations_tbl)

## Check if a location is duplicated
scrape_locations_tbl %>%
  #filter(country == "Nigeria") %>%
  group_by(location) %>%
  summarise(freq = n()) %>%
  arrange(-freq, location) %>%
  group_by(freq) %>%
  summarise(n = n())

## Number of locations per country
scrape_locations_tbl %>%
  group_by(country) %>%
  summarise(n = n())

## Covered locations are much smaller than those covered
# scrape_locations_sf %>%
#   as_tibble() %>%
#   group_by(covered) %>%
#   summarise(mean_area_circle_km = mean(area_circle_km))

###### Join data
# Takes a while to join
scraper_help <- names_scrape %>%
  left_join(scrape_locations_tbl, by = "country") %>%
  filter(!is.na(geocode)) %>%
  arrange(date)

#mutate(proxy_no = rep(1:nrow(proxy), length.out = nrow(.))) %>% # repeat 1-300 to add proxy IPs
#left_join(proxy, by = "proxy_no") %>% # add rotating proxies
#mutate(port = as.integer(port))

