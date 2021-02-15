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

# Boundaries to collect Tweets from

# Subset before joining (otherwise will be slow)
gadm_bbox <- st_bbox(gadm_1)

bbox_wrap <- function(x) st_as_sf(x)

gadm_1 %>%
  as_tibble() %>%
  group_by(name_0) %>%
  summarise(geometry = st_union(geometry)) %>%
  mutate(geometry = st_sfc(geometry))


  nest() %>%
  unnest() %>%
  
  mutate(bbox = map(data, bbox_wrap))




st_crop(gpw_5, gadm_bbox)

## Join raster data with boundary data
### Double check the kind of join desired, some overlap
ras_5_bound <- st_join(gpw_5, gadm_1, join = st_nearest_feature)


  filter(!is.na(name_0)) %>%
  mutate(across(c(name_0, name_1, engtype_1), as.character))

## Add centroids
ras_5_bound$centroid <- st_centroid(ras_5_bound$geometry)

# Correct for rasters that cross between 

# Print largest per subregion
ras_5_bound %>%
  as.data.frame() %>%
  filter(name_0 == "Jordan") %>%
  group_by(name_1) %>%
  slice_max(order_by = pop, n = 3) %>%
  arrange(name_1, pop)

# Plot
ras_5_bound %>%
  filter(name_0 == "Jordan") %>%
  ggplot() +
  geom_sf(aes(fill = log(pop))) +
  geom_sf(data = gadm_1[gadm_1$name_0 == "Jordan",], fill = NA, colour = "red")

###### Bind data
get_help <- reign %>%
  left_join(cap_geo, by = "country") %>%
  mutate(proxy_no = rep(1:nrow(proxy), length.out = nrow(.))) %>% # repeat 1-300 to add proxy IPs
  left_join(proxy, by = "proxy_no") %>% # add rotating proxies
  mutate(port = as.integer(port))

