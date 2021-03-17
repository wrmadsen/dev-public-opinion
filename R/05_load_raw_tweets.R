#' Read tweets
#'
#' @param json_path
#' @return List of raw tweets tibbles.
read_tweets_back <- function(json_path){

  df <- stream_in(file(json_path)) %>%
    as_tibble()

  df$filename <- json_path

  df

}
