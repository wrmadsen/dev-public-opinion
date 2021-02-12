###### Format data for getting Tweets

###### Clean
# Geocodes
cap_geo <- cap_geo_raw %>%
  clean_names() %>%
  mutate(geocode = paste0(capital_latitude, ",", capital_longitude, ",20km")) %>%
  select(country = country_name, capital = capital_name, geocode)

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
## Join raster data with boundary data
### Double check the kind of join desired, some overlap
gpw_30_ext <- gpw_30 %>%
  # bind_cols(gpw_centroids) %>%
  # select(pop, centroid_x, centroid_y) %>%
  # as_tibble() %>%
  # st_as_sf(coords = c("centroid_x", "centroid_y"), crs = 4326) %>%
  st_join(.,
          gadm_1) %>%
  filter(!is.na(name_0)) %>%
  mutate(across(c(name_0, name_1, engtype_1), as.character))

d <- gpw_30_ext %>%
  as.data.frame() %>%
  mutate(geometry = as.character(geometry)) %>%
  group_by(geometry) %>%
  mutate(n = n())

gpw_30_ext %>%
  as.data.frame() %>%
  filter(name_0 == "Jordan") %>%
  group_by(name_) %>%
  summarise(pop  = sum(pop))

class(gpw_30_ext)

###### Bind data
get_help <- reign %>%
  left_join(cap_geo, by = "country") %>%
  mutate(proxy_no = rep(1:nrow(proxy), length.out = nrow(.))) %>% # repeat 1-300 to add proxy IPs
  left_join(proxy, by = "proxy_no") %>% # add rotating proxies
  mutate(port = as.integer(port))

