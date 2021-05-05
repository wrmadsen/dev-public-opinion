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

# Get tweets
#source("data-raw/03_get_tweets.R")

## Read tweets ----
tweets_raw <- read_csv("data-raw/tweets/tweets.csv")

# Save as single object
#save(tweets_raw, file = "data/tweets_raw.RData")

## Format tweets ----
# Load raw tweets
#load("data/tweets_raw.RData")

#tweets_raw_small <- tweets_raw[1:300000,]

# Format and add variables
tweets_formatted <- format_tweets(tweets_raw, candidates)

# Filter out NA leaders and duplicates
tweets_sub <- filter_tweets(tweets_formatted)

# Add GADM regions
tweets_sf <- add_regions(tweets_sub, boundaries_subnational)

# Create tweets tokens
tweets_tokens <- create_tweet_tokens(tweets_sf)

# Save formatted data ----
# save(supp, reign, candidates,
#      elex_master, polling_master,
#      boundaries_national, boundaries_subnational,
#      tweets_sf, tweets_tokens,
#      senti_lexicons, afinn, afinn_stem,
#      file = "data/formatted_data.RData")

save(tweets_sf,
     file = "data/tweets_sf.RData")

save(tweets_tokens,
     file = "data/tweets_tokens.RData")

save(supp, reign, candidates,
     elex_master, polling_master,
     polling_elex_master, gdl_interpo,
     file = "data/formatted_supplementary.RData")

save(boundaries_national, boundaries_subnational,
     file = "data/formatted_gadm.RData")

save(senti_lexicons, afinn, afinn_stem,
     file = "data/formatted_dictionary.RData")

