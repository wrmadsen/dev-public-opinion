# Format tweets

# Tidy and format tweets ------
tweets <- tweets_raw %>%
  clean_names() %>%
  # unite(col = "hashtags_", contains("hashtags."), na.rm = TRUE) %>%
  # unite(col = "photos_", contains("photos."), na.rm = TRUE) %>%
  # unite(col = "urls_", contains("urls."), na.rm = TRUE) %>%
  # relocate(matches("//d|0"), .after = last_col()) %>%
  mutate(date = as.Date(date),
         leader = gsub("data.+/|_.+", "", filename)
  ) %>%
  left_join()
  select(id, username, name, date, country, leader, place)

tweets

names(tweets)