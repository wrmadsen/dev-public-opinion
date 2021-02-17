###### Format data for getting Tweets

###### Clean
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
  transmute(across(c(name_0, name_1, engtype_1), as.character),
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

## Identify points/circles that are covered by another
### Check for each point if any points fall under its radius
point_distances <- st_distance(scrape_points, scrape_points)

points_covered <- point_distances %>%
  as_tibble() %>%
  mutate(point1 = row_number()) %>%
  pivot_longer(1:ncol(.)-1, names_to = "point2", values_to = "distance_m") %>%
  mutate(point2 = gsub("V", "", point2) %>% as.integer,
         distance_m = as.double(distance_m)
         ) %>%
  left_join(., scrape_points %>% as.data.frame() %>% select(row_number, radius_m),  # join dataset with radius column
            by = c("point1" = "row_number")) %>%
  # check if distance to another point is lower than radius, remove distance to itself (0)
  filter(distance_m != 0) %>%
  mutate(covered = if_else(distance_m - radius_m < 0, 1, 0)) %>%
  group_by(point1) %>%
  summarise(covered = max(covered)) %>%
  select(point1, covered) %>%
  arrange(point1) 

# Add coverage and buffer to create scraper circles
scrape_circles <- scrape_points %>%
  st_buffer(., .$radius_m) %>%
  left_join(., points_covered, by = c("row_number" = "point1"))

## Simplify circles for plotting
scrape_circles_simp <- st_simplify(scrape_circles, dTolerance = 1000)

# Create main scraper locations object
## Could add code to subset number of locations used for each region
## e.g. three most populous, with largest circles, random, etc.
scrape_locations_sf <- scrape_points %>%
  left_join(., points_covered, by = c("row_number" = "point1")) %>%
  st_transform(4326) %>% # transform back to 4326 to get long and lat
  mutate(x = st_coordinates(geometry)[,1],
         y = st_coordinates(geometry)[,2]
  ) %>%
  mutate(area_circle_m = st_area(scrape_circles$geometry),
         area_circle_km = as.double(area_circle_m)/1000000,
         radius_km = radius_m/1000,
         geocode = paste0(x, ",", y, ",", radius_km, "km")
  )

## Subset variables for join
scrape_locations <- scrape_locations_sf %>%
  as_tibble() %>%
  select(country = name_0, region = name_1, region_type = engtype_1, gpw_smallest, geocode)

## Number of locations per country
scrape_locations %>%
  group_by(country) %>%
  summarise(n = n())

## Number of points at lowest GPW admin level
scrape_locations_sf %>%
  as_tibble() %>%
  group_by(gpw_smallest) %>%
  transmute(name1, name2, name3, name_0, name_1, gpw_smallest, n = n()) %>%
  arrange(-n)

## Number of locations covered by another
table(scrape_locations_sf$covered)

## Covered locations are much smaller than those covered
scrape_locations_sf %>%
  as_tibble() %>%
  group_by(covered) %>%
  summarise(mean_area_circle_km = mean(area_circle_km))

###### Join data
# Takes a while to join
scraper_help <- reign %>%
  left_join(scrape_locations, by = "country")
#mutate(proxy_no = rep(1:nrow(proxy), length.out = nrow(.))) %>% # repeat 1-300 to add proxy IPs
#left_join(proxy, by = "proxy_no") %>% # add rotating proxies
#mutate(port = as.integer(port))

scraper_help %>%
  filter(country == "Nigeria")
