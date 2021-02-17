###### Master script

# Load packages
source("src/R/00_packages.R")

# Load data
source("src/R/01_load_data.R")

# Format data
source("src/R/02_format_data.R")

# Format scraper help data
source("src/R/02_format_get_help.R")

# Get tweets
## Time consuming, be aware
#source("src/R/03_get_tweets.R")

# Load tweets
source("src/R/04_load_tweets.R")

# Format tweets
source("src/R/05_format_tweets.R")


# Sentiment analysis
# Extract individual-level covariates
# Esimate public support by country and region
# MRP model to predict by region?

# Plot
source("src/R/00_plots.R")


