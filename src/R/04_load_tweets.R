###### Load tweets

###### Load all Tweets
# Circa size of Tweets
file.size("data/tweets")/1000 # mb

# Function to read in and add file name as column
read_tweets_back <- function(csv){
  
  df <- stream_in(csv) %>%
    as_tibble()
  
  df$filename <- csv
  
  df
  
}

#read_tweets_back("data/tweets/Buhari2018-01-03.json")

# Map across function load all Tweets
tweets_raw <- list.files("data/tweets/", full.names = TRUE) %>%
  map_df(~read_tweets_back(.))