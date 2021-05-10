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
library(data.table)
library(quanteda)
library(re2)

# Source R functions
list.files("R", full.names = TRUE) %>% purrr::map(source)

# Load raw data -----
source("data-raw/01_load_raw.R")

# Format raw data -----
source("data-raw/02_format_raw_data.R")

# Update data to collect tweets ----
#source("data-raw/03_data_to_get_tweets.R")

# Read tweets ----
tweets_raw <- fread("data-raw/tweets/tweets_raw_og.csv", nThread = 10000)

# Format tweets ----

# Subset
#tweets_raw <- tweets_raw[1:300000,]

# Remove non-English
tweets_en <- remove_non_english(tweets_raw)

# Save English tweets raw
#fwrite(tweets_en, file = "data-raw/tweets/tweets_en.csv", nThread = 10000)
#tweets_en <- fread("data-raw/tweets/tweets_en.csv", nThread = 10000)

# Create leader names to match
candidates_match <- create_leaders_match(candidates)

# Get coordinates
tweets_en <- get_coordinates(tweets_en)

# Add leaders' names
tweets_cap <- add_leaders_to_tweets(tweets_en, candidates)

# Filter out duplicates and Tweets that don't mention a leader
tweets_sub <- filter_tweets(tweets_cap)

# Add GADM regions
tweets_sf <- add_regions(tweets_sub, boundaries_subnational)

# Create tweets tokens
tokens_master <- create_tweets_tokens(tweets_sub)
#tokens_master <- fread("data/tokens_master.csv")

# Join sentiment values by stem
senti_tokens <- add_sentiment_to_tokens(tokens_master, afinn_stem)

# Save formatted data ----

save(tweets_sf, file = "data/tweets_sf.RData")

fwrite(tweets_sub, file = "data/tweets_sub.csv", nThread = 8)

#fwrite(tokens_master, file = "data/tokens_master.csv", nThread = 4)

fwrite(senti_tokens, file = "data/senti_tokens.csv", nThread = 8)

save(supp, reign, candidates,
     elex_master, polling_master,
     polling_us,
     targets_master, gdl_interpo,
     file = "data/formatted_supplementary.RData")

save(boundaries_national, boundaries_subnational,
     file = "data/formatted_gadm.RData")


