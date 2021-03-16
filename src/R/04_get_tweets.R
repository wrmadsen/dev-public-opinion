###### Get Tweets with Python's twint

# Get tweets without point data -------
get_tweets_r <- function(scrape_data, path = "data-raw/tweets/without/", limit, geocode = ""){
  
  scrape_data %>%
    mutate(file_path = paste0(path, name, "_", paste(date), ".json"), # name of file to be saved
           date = paste0(date, " 00:00:00"),
           date_end = paste0(date_end, " 23:59:59")
    )
  
    # mutate(tweets = pmap(list(name, date, date_end, file_path),
    #                      ~get_tweets(..1,
    #                                  "en",
    #                                  geocode, # no geocode
    #                                  limit, # limit
    #                                  ..2,
    #                                  ..3,
    #                                  ..4
    #                      )
    # )
    # )
  
}

