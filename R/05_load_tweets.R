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
