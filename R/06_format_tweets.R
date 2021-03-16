# Format tweets

# Tidy and format tweets ------
format_tweets <- function(tweets_raw, candidates){
  
  # Look-up to add leaders and countries
  candidates <- distinct(candidates, country, name)
  
  # Format long and lat
  tweets <- tweets_raw %>%
    mutate(x = purrr::map(place.coordinates, 1) %>% paste %>% as.double,
           y = purrr::map(place.coordinates, 2) %>% paste %>% as.double
    )
  
  # Clean and select variables
  tweets %>%
    clean_names() %>%
    # unite(col = "hashtags_", contains("hashtags."), na.rm = TRUE) %>%
    # unite(col = "photos_", contains("photos."), na.rm = TRUE) %>%
    # unite(col = "urls_", contains("urls."), na.rm = TRUE) %>%
    # relocate(matches("//d|0"), .after = last_col()) %>%
    mutate(date = as.Date(date),
           week = floor_date(date, "week"),
           leader = gsub("data.+/|_.+", "", filename),
    ) %>%
    left_join(., 
              candidates,
              by = c("leader" = "name")) %>%
    select(id, username, name, date, week, country, leader,
           x, y, language, tweet)
  
}

