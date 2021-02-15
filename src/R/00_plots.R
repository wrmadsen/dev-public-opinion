###### Plot



###### English-speakers plot
# Plot different data on English speakers
supp %>%
  ggplot(.,
         aes(x = eng_prop_wiki,
             y = eng_prop) # ethno
  ) +
  geom_point() +
  geom_label_repel(aes(label = paste0(country, " ", year))) +
  labs(title = "Different sources on English speakers per country")

# Plot English speaking population against corruption index
supp %>%
  #filter(wgi_est < 1) %>%
  filter(twitter_users_pc < 0.3) %>%
  ggplot(.,
         aes(x = twitter_users_pc,
             y = eng_prop)) +
  geom_point() +
  geom_label_repel(aes(label = paste0(country, " ", year))) +
  labs(title = "English-speaking share by voice and accountability index")

# Plot number of tweets every week
tweets %>%
  filter(country == "Nigeria") %>%
  mutate(week = floor_date(date, unit = "week"),
         month = floor_date(date, unit = "month")
  ) %>%
  group_by(month, country, leader) %>%
  summarise(n = n()) %>%
  ggplot(.,
         aes(x = month,
             y = n)) +
  geom_col() +
  labs(title = "Number of Tweets mentioning Buhari in Lagos, Nigeria",
       subtitle = paste0(nrow(tweets), " tweets from Lagos")
  ) 


# Map Tweets as points
world1 <- map("world", plot = FALSE, fill = TRUE) %>% sf::st_as_sf()
sf::st_as_sf(map("africa", plot = FALSE, fill = TRUE))

# Nigeria NE
nigeria_sf <- world1 %>% filter(ID == "Nigeria")

tweets_n <- nrow(tweets)
tweets_n_w_points <- nrow(tweets[!is.na(tweets$place_coordinates_0),])

ggplot() +
  geom_sf(data = nigeria_sf) +
  coord_sf(xlim = c(8.5, 9.5), ylim = c(7, 7.7), expand = FALSE) +
  geom_point(data = tweets, aes(x = place_coordinates_0, y = place_coordinates_1),
             size = 0.7) +
  labs(title = "Lagos in Nigeria: Tweets which included point spatial data",
       subtitle = paste0(tweets_n_w_points, " of ", tweets_n, " tweets include spatial data")
  ) +
  theme_bw()


# Plot shapefiles data from GDL
subnat %>%
  filter(country == "Afghanistan") %>%
  #filter(year == 2018) %>%
  ggplot(.) +
  geom_sf(aes(fill = popshare)) +
  geom_text(aes(label = region, x = centroid_X, y = centroid_Y)) +
  facet_wrap(~year)

###### Methodology plots
# Plot scraper circles
scrape_circles %>%
  filter(countrynm == "Jordan") %>%
  ggplot() +
  geom_sf(colour = "red", show.legend = FALSE, fill = NA) +
  geom_sf(data = scrape_points[scrape_points$name_0 == "Jordan",],
          colour = "blue") +
  geom_sf(data = st_transform(gadm_1[gadm_1$name_0 == "Jordan",], 27700),
          colour = "black", fill = NA)



