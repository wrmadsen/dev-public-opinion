# Format tweets

# Tidy and format tweets ------
tweets <- tweets_raw %>%
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
            distinct(candidates, country, name),
            by = c("leader" = "name")) %>%
  select(id, username, name, date, week, country, leader, place, tweet)

# Print head
head(tweets)

# Dimensions
dim(tweets)
