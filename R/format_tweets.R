# Get tweets ----
#' Get tweets per period
#'
#' @param scrape_data
#' @param limit
#' @param include_geocode
#' @return Raw tweets saved to path in a JSON per period
get_tweets_per <- function(scrape_data, limit = 1000000, include_geocode = FALSE){

  # Subset based on path and geocode
  scrape_data_sub <- scrape_data %>%
    mutate(include_geocode = include_geocode,
           file_path = if_else(include_geocode,
                               paste0("data-raw/tweets/with/", name, "_", paste(date), ".json"),
                               paste0("data-raw/tweets/without/", name, "_", paste(date), ".json")
           ),
           date = paste0(date, " 00:00:00"),
           date_end = paste0(date_end, " 23:59:59"),
           geocode = if_else(include_geocode, geocode, ""),
    ) %>%
    transmute(search = name,
              geo = geocode,
              limit = limit,
              since = date,
              until = date_end,
              path = file_path
    ) #%>% view

  # Set up parallel queries
  no_cores <- availableCores() - 2
  #plan(cluster)
  #plan(sequential)
  plan(multicore, workers = no_cores)

  # Map with future
  future_pwalk(scrape_data_sub, get_tweets, .progress = TRUE)
  #future_pmap(scrape_data_sub, get_tweets, .progress = TRUE)

}

#' Get tweets total
#'
#' @param scrape_data
#' @param limit
#' @param include_geocode
#' @return Raw tweets saved to path in a JSON per period
get_tweets_total <- function(scrape_data, limit = 1000000000, include_geocode = FALSE){

  # Subset based on path and geocode
  scrape_data_sub <- scrape_data %>%
    group_by(country, name, geocode) %>%
    summarise(date = min(date),
              date_end = max(date_end),
              include_geocode = include_geocode
    ) %>%
    ungroup() %>%
    transmute(search = name,
              geo = if_else(include_geocode, geocode, ""),
              limit = limit,
              since = paste0(date, " 00:00:00"),
              until = paste0(date_end, " 23:59:59"),
              path = if_else(include_geocode,
                             paste0("data-raw/tweets/total/", name, "_",
                                    paste(date), "_to_", paste(date_end), "_with.json"),
                             paste0("data-raw/tweets/total/", name, "_",
                                    paste(date), "_to_", paste(date_end), "_without.json")
              )
    ) #%>% view

  # Map across Python function
  pmap(scrape_data_sub, get_tweets)

}


# Load tweets ----
#' Read raw tweets from JSONs
#'
#' @param json_path path to folder with JSON files of raw tweets
#' @return List of raw tweets tibbles
read_tweets_back <- function(json_path){

  tweets_raw <- jsonlite::stream_in(file(json_path)) %>%
    flatten() %>%
    as_tibble()

  tweets_raw$filename <- json_path

  tweets_raw

}

#' Bind raw tweets into tibble
#'
#' @param tweets_raw List of raw tweets tibbles
#' @return Single tibble of raw tweets
bind_raw_tweets <- function(tweets_raw){

  # Use map to clean before binding tibbles in a list
  tweets_raw %>%
    purrr::map(~mutate(., place = "") # need to add place to
    ) %>%
    bind_rows()

}

# Format tweets -----
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
    ) %>% view
    left_join(.,
              candidates_lookup,
              by = c("leader" = "name")) %>%
    select(id, username, name, date, country, leader,
           x, y, language, tweet, replies_count, retweets_count, likes_count)

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
    st_as_sf(., coords = c("y", "x"), crs = 4326)

  tweets_no_points <- tweets_formatted %>%
    filter(is.na(x)) %>%
    select(-c(x, y))

  # Find intersections between points and polygons
  intersections <- st_intersects(tweets_points, boundaries_subnational)

  # Create region-row-number look-up
  region_look_up <- boundaries_subnational %>%
    as.data.frame() %>%
    transmute(region_id = row_number(),
              region_1)

  # Add regions to tweets with points
  tweets_w_regions <- tweets_points %>%
    mutate(region_id = as.integer(intersections)
    ) %>%
    left_join(., region_look_up, by = "region_id")

  # Add non-point tweets back if there are any
  if (nrow(tweets_no_points) == 0) {

    tweets_w_regions

  } else {

  tweets_w_regions %>%
    bind_rows(tweets_no_points)

  }

}
