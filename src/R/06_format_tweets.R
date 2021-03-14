###### Format tweets

# Tidy and format tweets ------
tweets <- tweets_raw %>%
  # select(contains("hashtags.")) %>%
  # view()
  unite(col = "hashtags_", contains("hashtags."), na.rm = TRUE) %>%
  unite(col = "photos_", contains("photos."), na.rm = TRUE) %>%
  unite(col = "urls_", contains("urls."), na.rm = TRUE) %>%
  relocate(matches("//d|0"), .after = last_col()) %>%
  mutate(filename,
         date = as.Date(date),
         country = gsub(".*_(.*)_.*", "\\1", filename),
         leader = gsub(paste0(".*//(.*)_", country, ".*"), "\\1", filename)
  ) %>%
  clean_names() %>%
  select(date, name, country, leader, place, everything(),-c(contains("mentions"), contains("reply"), "filename"))

tweets

names(tweets)