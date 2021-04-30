# Master formatting
## Tidy raw data and save as formatted

# Load packages -----
library(tidyverse)
library(jsonlite)
library(sf)
library(tidytext)
library(readxl)
library(janitor)
library(lubridate)
library(spatstat)
library(maptools)
library(reticulate)
library(future)
library(furrr)
library(textdata)
library(haven)

# Source R functions
list.files("R", full.names = TRUE) %>% purrr::map(source)

# Load raw data -----
source("data-raw/01_load_raw.R")

# Format raw data -----
source("data-raw/02_format_raw_data.R")

# Helper data for getting tweets -----

## All ----
# Create object with get frequency and names
# People names must match between reign and people_to_get
get_names_all <- create_get_freq(reign, candidates, by_type = "days", by_n = 5)

# Join data
get_data_all <- get_names %>%
  left_join(geocodes, by = "country") %>%
  filter(!is.na(geocode)) %>%
  arrange(name, desc(date)) # descending to get recent tweets first

# Save get data as csv
# Multiprocessing in Python cut time from 150 secs to 22 secs (14x as fast)
(get_data_all_csv <- get_data_all %>%
    filter(country %in% c("Georgia", "Zimbabwe", "Mexico")) %>%
    transmute(leader = name,
              date = paste(date),
              date_end = paste(date_end),
              row_no = paste0(row_number(), "/", n())
    )
)

get_data_all_csv$leader %>% unique

write_csv(get_data_all_csv, "py/get_data_all.csv")

## With geocodes ----
# Frequency for collecting tweets with geocodes can be larger to save time
get_names_geo <- create_get_freq(reign, candidates, by_type = "days", by_n = 200)

# Create smallest possible circles
small_circs <- create_smallest_possible(boundaries_national)

# Find radius and centre coordinates
centre_and_radius <- find_centre_and_radius(small_circs)

# Create geocodes
geocodes <- centre_and_radius %>%
  transmute(country, geocode = paste0(x, ",", y, ",", radius_m/1000, "km"))

# Join geocodes and arrange data
get_data_geo <- get_names_geo %>%
  left_join(geocodes, by = "country") %>%
  filter(!is.na(geocode)) %>%
  arrange(name, desc(date)) # descending to get recent tweets first

# Save get data as csv
# Multiprocessing in Python cut time from 150 secs to 22 secs (14x as fast)
(get_data_geo_csv <- get_data_geo %>%
    #filter(country %in% c("Georgia", "Zimbabwe", "Mexico")) %>%
    transmute(leader = name,
              date = paste(date),
              date_end = paste(date_end),
              row_no = paste0(row_number(), "/", n()),
              geocode

    )
)

get_data_geo %>% distinct(country, name) %>% arrange(country)

write_csv(get_data_geo_csv, "py/get_data_geo.csv")

# Get tweets ----
# This stage takes place in Python, outside of R, for now
# Try to source py script with reticulate in the future to keep pipeline in R
#use_python("/usr/local/bin/python3", required = TRUE)
#use_virtualenv("~/venv/", required = TRUE)

#source_python("py/get_tweets_multi.py", convert = FALSE)

#py_run_file("py/get_tweets_multi.py")

## Read tweets ----
tweets_raw <- read_csv("data-raw/tweets/tweets.csv")

# Save as single object
#save(tweets_raw, file = "data/tweets_raw.RData")

## Format tweets ----
# Load raw tweets
#load("data/tweets_raw.RData")

tweets_raw_small <- tweets_raw[1:300000,]

# Format and add variables
tweets_formatted <- format_tweets(tweets_raw, candidates)

# Filter out NA leaders and duplicates
tweets_sub <- filter_tweets(tweets_formatted)

# Add region variables
tweets_sf <- add_regions(tweets_sub, boundaries_subnational)

# Create tweets tokens
tweets_tokens <- tweets_sf %>%
  create_tweet_tokens()

# Save formatted data ----
save(supp, reign, candidates,
     elex_master, polling_master,
     boundaries_national, boundaries_subnational,
     tweets_sf,
     senti_lexicons, afinn, afinn_stem,
     file = "data/formatted_data.RData")

