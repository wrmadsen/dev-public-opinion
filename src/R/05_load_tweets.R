###### Load tweets

###### Load all Tweets
# Circa size of Tweets
file.size("data/tweets/nigeria")/1000 # mb

# Function to read in and add file name as column
read_tweets_back <- function(json){
  
  df <- stream_in(file(json)) %>%
    as_tibble()
  
  df$filename <- json
  
  df
  
}

#read_tweets_back("data/tweets/Buhari2018-01-03.json")

# Map across function load all Tweets
tweets_raw <- list.files("data/tweets", full.names = TRUE, recursive = TRUE) %>%
  map_df(~read_tweets_back(.))


stream_in("data/tweets/Nigeria/Buhari_Bauchi_Bauchi_2019-01-12.json") %>% as_tibble()

fromJSON(paste(readLines("data/tweets/Nigeria/Buhari_Bauchi_Bauchi_2019-01-12.json"), collapse = ""))

stream_in(file("data/tweets/Nigeria/Buhari_Bauchi_Bauchi_2019-01-12.json")) %>% view
