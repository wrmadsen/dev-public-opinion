# Get tweets ----
#' Get tweets per period
#'
#' @param get_data
#' @param limit
#' @param include_geocode
#' @return Raw tweets saved to path in a JSON per period
# get_tweets_per <- function(get_data, limit = 1000000, include_geocode = FALSE){
#
#   # Subset based on path and geocode
#   get_data_sub <- get_data %>%
#     mutate(include_geocode = include_geocode,
#            file_path = if_else(include_geocode,
#                                paste0("data-raw/tweets/with/", name, "_", paste(date), ".json"),
#                                paste0("data-raw/tweets/without/", name, "_", paste(date), ".json")
#            ),
#            date = paste0(date, " 00:00:00"),
#            date_end = paste0(date_end, " 23:59:59"),
#            geocode = if_else(include_geocode, geocode, ""),
#     ) %>%
#     transmute(search = name,
#               geo = geocode,
#               limit = limit,
#               since = date,
#               until = date_end,
#               path = file_path
#     ) #%>% view
#
#   # Set up parallel queries
#   no_cores <- availableCores() - 1
#   #plan(cluster)
#   #plan(sequential)
#   future::plan(multicore)
#
#   # Map with future
#   future_pwalk(get_data_sub, get_tweets,
#                .options = furrr_options(lazy = FALSE,
#                                         scheduling = 1,
#                                         chunk_size = 1))
#
# }


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
#' @param candidates which people to get and when.
#' @return tweets with formatted coordinates, country, leader, and other variables.
format_tweets <- function(tweets_raw, candidates){

  # Look-up to add leaders and countries
  candidates_lookup <- candidates %>%
    distinct(country, name) %>%
    transmute(name = name,
              name_lower = tolower(name),
              leader_country = country)

  candidates_match <- paste(candidates_lookup$name_lower, collapse = "|")

  # Get long and lat coordinates
  tweets_coords <- tweets_raw %>%
    mutate(x = str_match(place, "\\[(.*?),")[,2] %>% as.double(),
           y = str_match(place, "\\d, (.*?)\\]")[,2] %>% as.double()
    )

  # Find which leader(s) is/are mentioned in tweet
  tweets_leader <- tweets_coords %>%
    mutate(leader_mentions = str_extract_all(tolower(tweet), candidates_match)) %>%
    rowwise() %>%
    mutate(leader_unique = length(unique(leader_mentions))) %>%
    ungroup()

  # Add leader name if single
  tweets_leader <- tweets_leader %>%
    mutate(leader = if_else(leader_unique == 1,
                            purrr::map(leader_mentions, 1) %>% paste,
                            NA_character_)
           )

  # Add back capitalised leader names
  tweets_cap <- tweets_leader %>%
    left_join(.,
              candidates_lookup %>% select(-leader_country) %>% rename(leader = name),
              by = c("leader" = "name_lower")
              ) %>%
    # USe capitalised leader names
    select(-leader) %>%
    rename(leader = leader.y)

  # Clean and select variables
  tweets_formatted <- tweets_cap %>%
    clean_names() %>%
    mutate(date = as.Date(date),
           week = floor_date(date, "week"),
    ) %>%
    left_join(.,
              candidates_lookup,
              by = c("leader" = "name")
              ) %>%
    select(id, conversation_id, username, name, date, week, leader_country, leader, leader_unique, leader_mentions,
           x, y, language, tweet, replies_count, retweets_count, likes_count)

  tweets_formatted

}

#' Filter tweets
filter_tweets <- function(tweets_formatted){

  # Remove duplicates by choosing the duplicate with most likes
  tweets_no_dups <- tweets_formatted %>%
    group_by(id, conversation_id) %>%
    slice_max(likes_count, n = 1, with_ties = FALSE) %>% # for duplicates, choose the one with most likes
    ungroup()

  # Remove tweets that don't mention a single leader
  tweets_no_dups %>%
    filter(!is.na(leader))

}


#' Add region variable to users who shared their point data
#'
#' @param tweets_formatted
#' @param boundaries_subnational
#' @return formatted tweets tibble with region names for some users
add_regions <- function(tweets_sub, boundaries_subnational){

  # Convert to tweets with points to sf
  tweets_points <- tweets_sub %>%
    filter(!is.na(x)) %>%
    st_as_sf(., coords = c("y", "x"), crs = 4326) %>%
    mutate(has_point = TRUE)

  tweets_no_points <- tweets_sub %>%
    filter(is.na(x)) %>%
    select(-c(x, y)) %>%
    mutate(has_point = FALSE)

  # Find intersections between points and polygons
  intersections <- st_intersects(tweets_points, boundaries_subnational)

  # Create region-row-number look-up
  region_look_up <- boundaries_subnational %>%
    as.data.frame() %>%
    transmute(region_id = row_number(),
              country,
              region_1,
              engtype_1,
              region_2,
              engtype_2
              )

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
