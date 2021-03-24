context("Validation functions")

# Set up
source("R/validation.R")
load("data/formatted_data.RData")

test_that("Election regions can be found in GADM regions", {

  expect_equal(tweets_sf$region_1 %>% .[!is.na(.)] %>% unique() %in% elex_master$region_1 %>% all(),
               TRUE)

})
