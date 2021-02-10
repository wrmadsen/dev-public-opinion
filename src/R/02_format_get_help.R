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

# Proxy IPs
# proxy <- tibble(proxy = html_nodes(proxy_raw, "#proxylisttable td:nth-child(1)") %>% html_text(trim = TRUE),
#                 port = html_nodes(proxy_raw, "#proxylisttable td:nth-child(2)") %>% html_text(trim = TRUE),
#                 https = html_nodes(proxy_raw, "#proxylisttable td:nth-child(7)") %>% html_text(trim = TRUE)
# ) %>%
#   filter(https == "yes") %>% # only https types
#   transmute(proxy,
#             port,
#             proxy_type = "http",
#             proxy_no = row_number()
#             )
#
# proxy <- read_tsv("https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=100&country=all&ssl=all&anonymity=all&simplified=true") %>%
#   rename(proxy = 1) %>%
#   transmute(port = gsub(".+:", "", proxy) %>% as.integer,
#             proxy = gsub("\\:.*", "", proxy),
#             proxy_type = "http",
#             proxy_no = row_number()
#   )

###### Bind data
get_help <- reign %>%
  left_join(cap_geo, by = "country") %>%
  mutate(proxy_no = rep(1:nrow(proxy), length.out = nrow(.))) %>% # repeat 1-300 to add proxy IPs
  left_join(proxy, by = "proxy_no") %>% # add rotating proxies
  mutate(port = as.integer(port))