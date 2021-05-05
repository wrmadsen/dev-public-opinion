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

# Source R functions
list.files("R", full.names = TRUE) %>% purrr::map(source)

# Load raw data -----
source("data-raw/01_load_raw.R")

# Format raw data -----
source("data-raw/02_format_raw_data.R")

# Get tweets ----
#source("data-raw/03_get_tweets.R")

# Read tweets ----
tweets_raw <- read_csv("data-raw/tweets/tweets.csv")

# Format tweets ----

# Subset
tweets_raw_small <- tweets_raw[1:200000,]

# Format and add variables
tweets_formatted <- format_tweets(tweets_raw_small, candidates)

# Filter out duplicates and Tweets that don't mention a leader
tweets_sub <- filter_tweets(tweets_formatted)

# Add GADM regions
tweets_sf <- add_regions(tweets_sub, boundaries_subnational)

# Create tweets tokens
tokens_master <- create_tweets_tokens(tweets_sub)

# Join sentiment values by stem
senti_tokens <- add_sentiment_to_tokens(tokens_master, afinn_stem)

senti_tokens %>% filter(!is.na(afinn_value)) %>% slice(1:100)

# Save formatted data ----
# save(supp, reign, candidates,
#      elex_master, polling_master,
#      boundaries_national, boundaries_subnational,
#      tweets_sf, tweets_tokens,
#      senti_lexicons, afinn, afinn_stem,
#      file = "data/formatted_data.RData")

save(tweets_sf,
     file = "data/tweets_sf.RData")

# save(tweets_tokens,
#      file = "data/tweets_tokens.RData")
#write_csv(tweets_tokens,
#          file = "data/tweets_tokens.csv")

fwrite(tweets_tokens, file = "data/tweets_tokens.csv")

save(supp, reign, candidates,
     elex_master, polling_master,
     polling_elex_master, gdl_interpo,
     file = "data/formatted_supplementary.RData")

save(boundaries_national, boundaries_subnational,
     file = "data/formatted_gadm.RData")

save(senti_lexicons, afinn, afinn_stem,
     file = "data/formatted_dictionary.RData")

