#' Get tweets
#'
#' @param scrape_data
#' @param limit
#' @param include_geocode
#' @return Raw tweets saved to path in a JSON per period
get_tweets_r <- function(scrape_data, limit = 1000000, include_geocode = FALSE){

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
    )

  # Map across Python function
  pmap(scrape_data_sub, get_tweets)

}


