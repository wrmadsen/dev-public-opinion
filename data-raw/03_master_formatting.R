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

# Source R functions
list.files("R", full.names = TRUE) %>% purrr::map(source)

# Load raw data -----
source("data-raw/01_load_raw.R")

# Format raw data -----
source("data-raw/02_format_raw_data.R")

# Get and format tweets -----

# Create object with scraping frequency and names
# People names must match between reign and people_to_scrape
scrape_names <- create_scrape_freq(reign, candidates)

# Create smallest possible circles
small_circs <- create_smallest_possible(boundaries_national)

# Find radius and centre coordinates
centre_and_radius <- find_centre_and_radius(small_circs)

# Create geocodes
geocodes <- centre_and_radius %>%
  transmute(country, geocode = paste0(x, ",", y, ",", radius_m/1000, "km"))

# Join data
scrape_data <- scrape_names %>%
  left_join(geocodes, by = "country") %>%
  filter(!is.na(geocode)) %>%
  arrange(name, desc(date)) # descending to get recent tweets first

# Save scrape data as csv
# Multiprocessing in Python cut time from 150 secs to 22 secs (14x as fast)
scrape_data_csv <- scrape_data %>%
  mutate(date = paste(date),
         date_end = paste(date_end)) %>%
  select(leader = name, date, date_end) %>%
  filter(leader == "Buhari") %>%
  filter(year(date) == 2015 & month(date) == 1 & week(date) %in% c(1,2) | year(date_end) == 2015 & month(date_end) == 1 & week(date_end) %in% c(1,2))

write_csv(scrape_data_csv, "py/scrape_data.csv")

# Get tweets ----
# This stage takes place in Python, outside of R, for now
# Try to source py script with reticulate in the future to keep pipeline in R
#use_python("/usr/local/bin/python3", required = TRUE)
use_virtualenv("~/venv/", required = TRUE)

source_python("py/get_tweets_multi.py", convert = FALSE)

py_run_file("py/get_tweets_multi.py")


## Bind tweets ----
# Map across function load all Tweets across hundreds of JSONs
tweets_raw_list <- list.files("data-raw/tweets/total",
                              full.names = TRUE, recursive = TRUE,
                              pattern = "_with\\."
) %>%
  purrr::map(~read_tweets_back(.))

# Bind tweets into dataframe
tweets_raw <- bind_raw_tweets(tweets_raw_list)

# Save as single object
#save(tweets_raw, file = "data/tweets_raw.RData")

## Format tweets ----
# Load raw tweets
#load("data/tweets_raw.RData")

# Format and add variables, including leader and country
tweets_formatted <- format_tweets(tweets_raw, candidates)

# Add region names
tweets_sf <- add_regions(tweets_formatted, boundaries_subnational)

## Add regional covariates to tweets -----

# Save formatted data ----
save(supp, reign, candidates,
     elex_master,
     boundaries_national, boundaries_subnational,
     tweets_sf,
     senti_lexicons, afinn, afinn_stem,
     file = "data/formatted_data.RData")
