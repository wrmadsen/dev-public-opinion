#' Create scraper frequency
#'
#' @param reign reign object with leaders' term length.
#' @param people_to_scrape which people to scrape and when.
#' @return scraping frequency dataset, where each row gives a string (a leader) and period to be used to scrape Tweets with twint.
create_scrape_freq <- function(reign, people_to_scrape, days){

  # Create object to GET tweets with
  # Each row will present a round of scraping
  reign %>%
    mutate(type = "leader") %>%
    bind_rows(people_to_scrape) %>%
    mutate(type = if_else(is.na(type), "candidate", type)) %>%
    arrange(country, end) %>%
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
    filter(date >= as.Date("2006-07-15")) %>% # when Twitter full version went live
    filter(!is.na(name)) %>%
    arrange(country, name, date)

}

#' Create smallest possible circles
#'
#' @param boundaries_national sf object with national boundaries.
#' @return smallest possible circles.
create_smallest_possible <- function(boundaries_national){

  # For loop to find circle for each country
  small_circs <- c()

  for (i in 1:nrow(boundaries_national)){

    # Create smallest-possible circle
    # need spatstat and maptools
    small_circ <- boundaries_national[i,] %>%
      sf::st_transform(3857) %>% # need planar projection
      sf::as_Spatial() %>%
      spatstat::as.owin() %>% # convert to owin to use boundingcircle()
      spatstat::boundingcircle() %>%
      st_as_sf() %>%
      st_set_crs(3857)

    # Add to vector
    small_circs[i] <- small_circ$geom

  }

  # Get country and id variables from GADM and add vector
  boundaries_national %>%
    as_tibble() %>%
    transmute(id = row_number(), country, geom = small_circs) %>%
    st_as_sf(crs = 3857) %>%
    st_transform(4326)

}

#' Find centre and radius
#'
#' @param small_circs find centre and radius of smallest possible circles.
#' @return centre and radius.
find_centre_and_radius <- function(small_circs){

  # Find centres in BNG
  small_centres <- small_circs %>%
    st_transform(., 27700) %>% # convert to British National Grid to work in meters, required for calculating radius
    st_centroid()

  # Convert circles to linestring before finding radius
  small_lines <- small_circs %>%
    st_transform(., 27700) %>% # convert to British National Grid to work in meters, required for the scraping radius
    st_cast(to = "MULTILINESTRING")

  # Find and add radius in metres
  small_circs$radius_m <- st_distance(small_lines$geom, small_centres$geom,
                                      by_element = TRUE,
                                      which = "Euclidean"
  )

  # Add centres in 4326 to object
  small_centres_4326 <- small_centres %>%
    st_transform(4326) %>%
    st_coordinates() %>%
    as_tibble() %>%
    transmute(x = X,
              y = Y,
              id = row_number())

  # Join
  small_circs %>%
    left_join(small_centres_4326, by = "id", keep = FALSE) %>%
    as_tibble()

}

