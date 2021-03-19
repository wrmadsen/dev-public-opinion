#' Format tweets
#'
#' @param tweets_raw raw tweets binded from JSONs.
#' @param candidates which people to scrape and when.
#' @return tweets with formatted coordinates, country, leader, and other variables.
format_tweets <- function(tweets_raw, candidates){

  # Look-up to add leaders and countries
  candidates_lookup <- distinct(candidates, country, name)

  # Format long and lat
  tweets <- tweets_raw %>%
    mutate(x = purrr::map(place.coordinates, 1) %>% paste %>% as.double,
           y = purrr::map(place.coordinates, 2) %>% paste %>% as.double
    )

  # Clean and select variables
  tweets_formatted <- tweets %>%
    clean_names() %>%
    mutate(date = as.Date(date),
           week = floor_date(date, "week"),
           leader = gsub("data.+/|_.+", "", filename),
    ) %>%
    left_join(.,
              candidates_lookup,
              by = c("leader" = "name")) %>%
    select(id, username, name, date, week, country, leader,
           x, y, language, tweet)

  tweets_formatted

}

#' Add region variable to users who shared their point data
#'
#' @param tweets_formatted
#' @param boundaries_subnational
#' @return formatted tweets tibble with region names for some users
add_regions <- function(tweets_formatted, boundaries_subnational){

  # Convert to tweets with points to sf
  tweets_points <- tweets_formatted %>%
    filter(!is.na(x)) %>%
    st_as_sf(., coords = c("x", "y"), crs = 4326)

  # Find intersections between points and polygons
  intersections <- st_intersects(tweets_points, boundaries_subnational)

  # Create region-row-number look-up
  region_look_up <- boundaries_subnational %>%
    as.data.frame() %>%
    transmute(region_id = row_number(),
              region_1)

  # Add regions and bind non-point tweets back together
  tweets_points %>%
    mutate(region_id = as.integer(intersections)
           ) %>%
    left_join(., region_look_up, by = "region_id") %>%
    bind_rows(tweets_formatted %>%
                filter(is.na(x)) %>%
                select(-c(x, y))
              )

}
