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

# Source R functions
list.files("R", full.names = TRUE) %>% purrr::map(source)

# Load raw data -----
source("data-raw/01_load_raw.R")

# Format raw data -----
source("data-raw/02_format_raw_data.R")

# Get and format tweets -----
## Longer step
## Scraper help data ----
# For losing candidates in an election, scrape tweets mentioning them two months before election
people_to_scrape <- candidates %>%
  mutate(elex_start = (elex_date - months(2)) %>% floor_date(., unit = "month")
  ) %>%
  select(country, name, start = elex_start, end = elex_date)

# Create object with scraping frequency and names
# People names must match between reign and people_to_scrape
scrape_freq_names <- create_scrape_freq(reign, people_to_scrape, days = 7)

# Create smallest possible circles
small_circs <- create_smallest_possible(boundaries_national)

# Find radius and centre coordinates
centre_and_radius <- find_centre_and_radius(small_circs)

# Create geocodes
geocodes <- centre_and_radius %>%
  transmute(country, geocode = paste0(x, ",", y, ",", radius_m/1000, "km"))

# Join data
scrape_data <- scrape_freq_names %>%
  left_join(geocodes, by = "country") %>%
  filter(!is.na(geocode)) %>%
  arrange(name, desc(date)) # descending to get recent tweets first

## Get tweets ----
# Source Python twint function
use_python("/usr/local/bin/python3", required = TRUE)

source_python("py/get_tweets.py", convert = FALSE)

# Get tweets per period
## Get tweets without points
#get_tweets_per(scrape_data, limit = 1000000, include_geocode = FALSE)

## Get tweets with points
#get_tweets_per(scrape_data, limit = 1000000, include_geocode = TRUE)

# Get total tweets
# get_tweets_total(scrape_data %>% filter(name %in% c("Ghani", "Karzai")), limit = 1000000000, include_geocode = TRUE)
#
# get_tweets_total(scrape_data %>% filter(name %in% c("Ghani")),
#                  limit = 1000000000, include_geocode = FALSE)


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
