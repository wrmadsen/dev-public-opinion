# Create scraper data
create_scrape_data <- function(reign, candidates_scrape, days){
  
  # Create object to GET tweets with
  # Each row will present a round of scraping
  reign %>%
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
    # Choose scraping frequency, day, week, or a number of days
    # Floor start and ceiling end of term period
    mutate(date = list(seq.Date(floor_date(start, "month"), ceiling_date(end, "month"), by = days))) %>%
    tidyr::unnest(date) %>%
    transmute(country = case_when(country == "USA" ~ "United States",
                                  TRUE ~ country),
              name,
              date = date, # scrape start time (since)
              date_end = date + days(days-1), # scrape end time (to)
    ) %>%
    filter(date >= as.Date("2006-07-15")) # when Twitter full version went live

    
}

# Create smallest possible circles
create_smallest_possible <- function(gadm){
  
  # Turn to owin
  gadm %>%
    st_transform(3857) %>% # need planar projection
    as_Spatial() %>%
    as.owin() %>%
    boundingcircle() %>%
    st_as_sf() %>%
    st_set_crs(3857)
  
}

# Add smallest-possible circles (spc) to dataframe
add_smallest_possible <- function(gadm, circs)

  gadm %>%
  as.data.frame() %>%
  mutate(id = row_number()) %>%
  select(-geometry) %>%
  st_set_geometry(., st_sfc(circs, crs = 3857)) %>%
  st_transform(4326)

}

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
scrape_data <- names_scrape %>%
  left_join(country_geocode, by = "country") %>%
  arrange(name, desc(date)) # descending to get recent tweets first
