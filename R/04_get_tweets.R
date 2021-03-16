###### Get Tweets with Python's twint

# Get tweets without point data -------
get_tweets_r <- function(scrape_data, path = "data-raw/tweets/without/", limit = FALSE, include_geocode = FALSE){
  
  scrape_data %>%
    mutate(file_path = paste0(path, name, "_", paste(date), ".json"), # name of file to be saved
           date = paste0(date, " 00:00:00"),
           date_end = paste0(date_end, " 23:59:59"),
           include_geocode = include_geocode,
           geocode = if_else(include_geocode, geocode, ""),
    ) %>%
    mutate(tweets = pmap(list(name, geocode, date, date_end, file_path),
                         ~get_tweets(..1,
                                     "en",
                                     ..2, # no geocode
                                     FALSE, # limit
                                     ..3,
                                     ..4,
                                     ..5
                         )
    )
    )
  
}

