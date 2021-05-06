# Format tweets -----
#' Format tweets
#'
#' @param tweets_raw raw tweets binded from JSONs.
#' @param candidates which people to get and when.
#' @return tweets with formatted coordinates, country, leader, and other variables.
add_leaders_to_tweets <- function(tweets_raw, candidates){

  # Look-up to add leaders and countries
  candidates_lookup <- candidates %>%
    distinct(country, name) %>%
    transmute(name = name,
              name_lower = tolower(name),
              leader_country = country)

  # Leader names to match with content of Tweets
  candidates_match <- paste(candidates_lookup$name_lower, collapse = "[^A-z]|[^A-z]")

  candidates_match <- paste0("[^A-z]", candidates_match, "[^A-z]")

  # Convert to data.table
  tweets_raw_dt <- as.data.table(tweets_raw)

  # Get long and lat coordinates
  tweets_raw_dt[, x := str_match(place, "\\[(.*?),")[,2] %>% as.double()]

  tweets_raw_dt[, y := str_match(place, "\\d, (.*?)\\]")[,2] %>% as.double()]

  tweets_raw_dt[, row_no := .I]

  # Find which leader(s) is/are mentioned in each tweet
  # Use data.table to speed up processing
  #tweets_raw_dt[, leader_mentions := str_extract_all(tolower(tweet), candidates_match)]

  # Tweets to lower case
  tweets_raw_dt[, tweet_lower := tolower(tweet)]

  # Extract names
  tweets_raw_dt[, leader_mentions := re2_match_all(tweet_lower, pattern = candidates_match)]

  # Unnest each Tweet list of leader mentions
  # to determine whether more than a single leader is mentioned
  tweets_unnested <- tweets_raw_dt[, .(leader_mentions = unlist(leader_mentions)),
                                   by = setdiff(names(tweets_raw_dt), "leader_mentions")]

  # Remove non-letter characters
  tweets_unnested[, leader_mentions := re2_replace_all(leader_mentions, "[^A-z\\s]", "")]

  # Remove leading or trailing spaces
  tweets_unnested[, leader_mentions := trimws(leader_mentions)]

  # Count number of unique leaders mentioned per Tweet
  tweets_unnested[, leader_count := length(unique(leader_mentions)), by = row_no]

  # Add leader name if single unique mention
  tweets_unnested[, leader_single := if_else(leader_count != 1, NA_character_, leader_mentions)]

  # Add leader's country and capitalised name
  tweets_cap <- merge(tweets_unnested,
                      candidates_lookup %>% rename(leader = name),
                      all.x = TRUE, by.x = "leader_single", by.y = "name_lower")

  Sys.sleep(3)

  tweets_cap

}


# # Clean and select variables
# tweets_formatted <- tweets_cap %>%
#   mutate(date = as.Date(date),
#          week = floor_date(date, "week"),
#   ) %>%
#   select(id, conversation_id, username, name, date, week, leader_country, leader, leader_count, leader_mentions,
#          x, y, language, tweet, replies_count, retweets_count, likes_count) %>%
#   tibble()
#
# tweets_formatted

#' Filter tweets
filter_tweets <- function(tweets_formatted){

  # Remove duplicates by choosing the duplicate with most likes
  # Group by id and conversation id
  # Use data.table again for speed
  tweets_formatted_dt <- as.data.table(tweets_formatted)

  tweets_no_dups <- tweets_formatted_dt[, .SD[1], by = list(id, conversation_id)]

  # Remove tweets that
  # don't mention a single leader
  # or are non-English
  tweets_no_dups[!is.na(leader) & language == "en"] %>%
    tibble()

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

    # Use rbind from data.table
    # Then convert back to sf object after binding
    # This saves time
    tweets_sub_sf <- rbind(as.data.table(tweets_w_regions),
                           tweets_no_points,
                           fill = TRUE) %>%
      st_sf()

  }

  # Check if any rows have been dropped
  stopifnot(nrow(tweets_sub_sf) == nrow(tweets_sub))

  Sys.sleep(1)

  # Return
  tweets_sub_sf

}

# Not used ----
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

#' #' Read raw tweets from JSONs
#' #'
#' #' @param json_path path to folder with JSON files of raw tweets
#' #' @return List of raw tweets tibbles
#' read_tweets_back <- function(json_path){
#'
#'   tweets_raw <- jsonlite::stream_in(file(json_path)) %>%
#'     flatten() %>%
#'     as_tibble()
#'
#'   tweets_raw$filename <- json_path
#'
#'   tweets_raw
#'
#' }
#'
#' #' Bind raw tweets into tibble
#' #'
#' #' @param tweets_raw List of raw tweets tibbles
#' #' @return Single tibble of raw tweets
#' bind_raw_tweets <- function(tweets_raw){
#'
#'   # Use map to clean before binding tibbles in a list
#'   tweets_raw %>%
#'     purrr::map(~mutate(., place = "") # need to add place to
#'     ) %>%
#'     bind_rows()
#'
#' }
