# Load tweets

# Function to read in and add file name as column
read_tweets_back <- function(json){
  
  tweets_raw <- stream_in(file(json)) %>%
    flatten() %>%
    as_tibble()
  
  tweets_raw$filename <- json
  
  tweets_raw
  
}


# Bindlists of raw tweets
bind_raw_tweets <- function(tweets_raw){
  
  # Use map to clean before binding tibbles in a list
  tweets_raw %>%
    purrr::map(~mutate(., place = "") # need to add place to 
    ) %>%
    bind_rows()
  
}