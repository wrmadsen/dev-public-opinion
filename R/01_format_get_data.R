#' Create get frequency
#'
#' @param reign reign object with leaders' term length.
#' @param candidates candidates of elections.
#' @return get frequency dataset, where each row gives a string (a leader) and period to be used to get Tweets with twint.
create_get_freq <- function(reign, candidates, targets_master, by_type = "days", by_n = 12){

  # Find first and last target date candidates with elections and polls
  candidates_first_and_last <- targets_master %>%
    # only select top 2 candidates per election or poll
    filter(name %in% candidates$name) %>%
    select(country, name, date = date_target)

  # Find term information for leaders
  # This supplements the above
  reign_first_and_last <- reign %>%
    pivot_longer(cols = c(start, end), names_to = "type", values_to = "date") %>%
    select(country, name, date)

  # Create master first and last object
  # Combine REIGN and candidates
  # Find earliest and last date
  first_and_last_master <- bind_rows(candidates_first_and_last,
                                     reign_first_and_last) %>%
    arrange(country, name, date) %>%
    group_by(country, name) %>%
    slice(1, n())

  # Pivot to start and end columns
  first_and_last_master <- first_and_last_master %>%
    mutate(type = if_else(row_number() == 1, "start", "end"),
           date = if_else(type == "start",
                          floor_date(date, "month") - months(3),
                          floor_date(date, "month") + months(3)),
           date = as.Date(date)
    ) %>%
    ungroup() %>%
    pivot_wider(names_from = type, values_from = date)

  # Create frequency by days or hours

  # By hours
  if (by_type == "days"){

    # Get by days
    first_and_last_master %>%
      rowwise() %>%
      mutate(date = list(seq.Date(start,
                                  end,
                                  by = paste0(by_n, " days")))
      ) %>%
      tidyr::unnest(date) %>%
      transmute(country = case_when(country == "USA" ~ "United States",
                                    TRUE ~ country),
                name,
                date , # get start time (since)
                date_end = date + days(by_n-1), # get end time (to)
      ) %>%
      # when Twitter full version went live
      filter(date >= as.Date("2006-07-15")) %>%
      # add timestamps to days
      mutate(date = paste0(date, " 00:00:00"),
             date_end = paste0(date_end, " 23:59:59")) %>%
      filter(!is.na(name)) %>%
      arrange(country, name, date)

  } else{

    # Collect by hours
    first_and_last_master %>%
      rowwise() %>%
      mutate(start = floor_date(start, "month") %>% paste0(., "00:00:00") %>% as.POSIXct(., tz = "UTC"),
             end = ceiling_date(end, "month") %>% paste0(., "23:59:59") %>% as.POSIXct(., tz = "UTC")
      ) %>%
      mutate(date = list(seq(start,
                             end,
                             by = paste0(by_n, " hour")))
      ) %>%
      tidyr::unnest(date) %>%
      transmute(country = case_when(country == "USA" ~ "United States",
                                    TRUE ~ country),
                name,
                date, # get start time (since)
                date_end = date + hours(by_n-1) + minutes(59) + seconds(59), # get end time (to)
      ) %>%
      filter(date >= as.Date("2006-07-15")) %>% # when Twitter full version went live
      filter(!is.na(name)) %>%
      arrange(country, name, date)

  }

}

#' Create smallest possible circles
#'
#' @param boundaries_national sf object with national boundaries.
#' @return smallest possible circles.
create_smallest_possible <- function(boundaries_national){

  # Simplify
  boundaries_national_simp <- boundaries_national %>%
    st_simplify(., dTolerance = 0.001)

  # For loop to find circle for each country
  small_circs <- c()

  for (i in 1:nrow(boundaries_national_simp)){

    # Create smallest-possible circle
    # need spatstat and maptools
    small_circ <- boundaries_national_simp[i,] %>%
      sf::st_transform(3857) %>% # need planar projection
      sf::as_Spatial() %>%
      as.owin() %>% # convert to owin to use boundingcircle()
      boundingcircle() %>%
      st_as_sf() %>%
      st_set_crs(3857)

    # Add to vector
    small_circs[i] <- small_circ$geom

  }

  # Get country and id variables from GADM and add vector
  boundaries_national_simp %>%
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
    st_transform(., 27700) %>% # convert to British National Grid to work in meters, required for the get radius
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

