###### Format data for getting Tweets

###### Clean
# Geocodes
# cap_geo <- cap_geo_raw %>%
#   clean_names() %>%
#   mutate(geocode = paste0(capital_latitude, ",", capital_longitude, ",20km")) %>%
#   select(country = country_name, capital = capital_name, geocode)

# Leadership from REIGN
reign <- reign_raw %>%
  clean_names() %>%
  select(country, leader, year, month) %>%
  filter(lag(leader) != leader | lead(leader) != leader) %>%
  mutate(date_type = if_else(lead(leader) != leader, "end", "start"),
         date = paste0(year, "-", str_pad(month, 2, "left", pad = "0"), "-01"),
         date = as.Date(date),
  ) %>%
  filter(!(year < 2006 & date_type == "end" | date_type == "start" & lead(year) < 2006)) %>% # drop terms before 2006 (Twitter's founding)
  select(country, leader, date_type, date) %>%
  group_by(country, leader, date_type) %>%
  mutate(term_n = paste0("term ", 1:n())) %>% # count terms per leader NEED TO ADJUST FOR NAMES, e.g. Løkke, father-son?
  ungroup() %>%
  pivot_wider(names_from = date_type, values_from = date) %>%
  mutate(start = if_else(is.na(start), end, start),
  ) %>%
  rowwise() %>%
  mutate(date = list(seq.Date(start, end, by = "day"))) %>%
  tidyr::unnest(date) %>%
  mutate(country = case_when(country == "USA" ~ "United States",
                             TRUE ~ country),
         date_plus_one = date + days(1)) %>%
  filter(date >= as.Date("2006-07-15")) # when Twitter full version went live

###### GPW admin unit data
gpw <- gpw_raw %>%
  clean_names() %>%
  arrange(countrynm, name1, name2, name3, name4, name5, name6) %>%
  select(countrynm, name1, name2, name3, name4, name5, name6, total_a_km, un_2020_e)

###### Format GADM subnational boundary data
# Only includes certain countries we'd picked out
gadm_1 <- gadm_1_raw %>%
  clean_names() %>%
  select(name_0, name_1, engtype_1, geometry)

###### Create scraper locations object
# Join region polygons and admin points and calculate smallest distance
# Cut off to only include GPW points which are within GADM regions
scrape_regions <- st_join(gadm_1, gpw) %>%
  arrange(countrynm, name1, name2) %>%
  st_transform(., 27700) # British National Grid to work in meters, required for the scraping radius

## Add GPW points to dataframe with region polygon geometry
## Ensures that points geometry are in same order as polygon region geometry
gpw_bng <- gpw %>%
  st_transform(., 27700) %>%
  select(-c(total_a_km, un_2020_e))

scrape_points <- scrape_regions %>%
  as_tibble() %>%
  select(-geometry) %>%
  left_join(., gpw_bng, by = c("countrynm", "name1", "name2", "name3", "name4", "name5", "name6")) %>%
  st_as_sf() %>%
  mutate(across(1:10, as.character),
         across(1:10, ~if_else(. == "NA", NA_character_, .)),
         gpw_smallest = case_when(!is.na(name6) ~ name6, # create variable with most granular GPW name
                                  !is.na(name5) ~ name5,
                                  !is.na(name4) ~ name4,
                                  !is.na(name3) ~ name3,
                                  !is.na(name2) ~ name2,
                                  !is.na(name1) ~ name1)
         ) %>%
  select(name_0, name_1, engtype_1, gpw_smallest,
         gpw_1 = name1, gpw_2 = name2, gpw_3 = name3, gpw_4 = name4, gpw_5 = name5, gpw_6 = name6,
         total_a_km, un_2020_e, geometry) %>%
  arrange(name_0, name_1, gpw_smallest)

# Calculate smallest distance
## Convert to linestring before calculating distance
## https://github.com/r-spatial/sf/issues/1290
scrape_regions_line <- st_geometry(obj = scrape_regions) %>%
  st_cast(to = "LINESTRING")

scrape_points$radius <- st_distance(scrape_regions_line, scrape_points, by_element = TRUE) # in meters

scrape_points <- scrape_points %>%
  mutate(radius_m = as.double(radius))

# Create circle polygon showing scraping area
## Reproject to 27700 first in order to buffer in meters
scrape_circles <- scrape_points %>%
  st_transform(., 27700) %>%
  st_buffer(., scrape_points$radius_m)

# Create main scraper locations object
## Can also subset number of locations used for each region
scrape_locations <- scrape_points %>%
  st_transform(4326) %>% # transform back to 4326 to get long and lat
  mutate(x = st_coordinates(geometry)[,1],
         y = st_coordinates(geometry)[,2]
  ) %>%
  mutate(area_circle = st_area(scrape_circles$geometry),
         area_circle_km = as.double(area_circle)/1000000,
         radius_km = radius_m/1000,
         geocode = paste0(x, ",", y, ",", radius_km, "km")
  ) %>%
  group_by()


###### Bind data
get_help <- reign %>%
  left_join(cap_geo, by = "country") %>%
  mutate(proxy_no = rep(1:nrow(proxy), length.out = nrow(.))) %>% # repeat 1-300 to add proxy IPs
  left_join(proxy, by = "proxy_no") %>% # add rotating proxies
  mutate(port = as.integer(port))

