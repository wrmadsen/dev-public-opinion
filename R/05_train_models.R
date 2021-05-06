# Train models

#' Add national level before joining
#' @df data with missing region_1 or region_2 levels
add_national_level <- function(df){

  df %>%
    mutate(country = if_else(is.na(country), leader_country, country),
           region_1 = if_else(is.na(region_1), "National", region_1),
           region_2 = if_else(is.na(region_2), region_1, region_2)
    )

}

#' Join targets (election and polls) to data
#' @param df
#' @param targets_master
join_targets <- function(df, targets_master, by_region = TRUE){

  # Join targets data

  # By region (default)
  if (by_region){

    left_join(df,
              targets_master,
              by = c("leader" = "name", "country", "region_1", "region_2"))

  } else{

    # Or just by country (e.g. if there are no "National" region levels)
    left_join(df,
              targets_master %>%
                filter(region_2 == "National") %>%
                select(-c(region_1, region_2)),
              by = c("leader" = "name", "country"))


  }
}


#' For each tweet, select the nearest target (poll or election) in time
#' One target per tweet (or more if same difference in days)
select_nearest_target <- function(df){

  # Find difference in days between Tweet and target date
  df_2 <- df %>%
    mutate(days_diff = (date - date_target) %>% as.integer,
           days_diff_abs = abs(days_diff)
    )

  # Select nearest election or poll for each sentiment day
  df_2 %>%
    group_by(target_id) %>%
    slice_min(days_diff_abs, n = 1) %>%
    ungroup() %>%
    arrange(leader, country, region_1, date)

  # # Find difference in days between Tweet and target date
  # df <- df %>%
  #   mutate(days_diff = (date - date_target) %>% as.integer,
  #          days_diff_abs = abs(days_diff)
  #   )
  #
  # # Select nearest election or poll for each sentiment day
  # # Use data.table for speed
  # df_dt <- as.data.table(df)
  #
  # df_dt[ , .SD[which.min(days_diff_abs)], by = target_id]

}

#' Add GDL covariates
add_gdl_covariates <- function(senti_targets, gdl_interpo){

  left_join(senti_targets, gdl_interpo,
            by = c("year", "country", "region_1" = "gadm_region"))

}

#' Create training data
create_training_data <- function(senti_targets_covars, type = "elex", less_than_days_diff = 70){

  # Elections training data

  if (type == "elex"){

    # Subset election rows
    train_data_elex <- senti_targets_covars %>%
      # create id to later subset test data
      mutate(id = row_number()) %>%
      filter(type == "election") %>%
      # remove Zimbabwe's 2013 election
      filter(!(country == "Zimbabwe" & year(date) == 2013)) %>%
      arrange(country, region_1, region_2, date_target)

    # All elections but the last per country
    (train_data_elex_first <- train_data_elex %>%
        group_by(country) %>%
        filter(date_target != max(date_target)) %>%
        ungroup() %>%
        filter(days_diff_abs < less_than_days_diff)
    )

  } else if(type == "polls"){

    # Polls trainings data
    # Subset polls rows
    # Polls before last election per country
    train_data_polls <- senti_targets_covars %>%
      filter(type == "poll") %>%
      arrange(country, region_1, region_2, leader) %>%
      mutate(target_before_last_elex = case_when(country == "Nigeria" & date_target < as.Date("2019-02-23") ~ TRUE,
                                                 country == "Zimbabwe" & date_target < as.Date("2018-07-03") ~ TRUE,
                                                 country == "Georgia" & date_target < as.Date("2013-10-27") ~ TRUE,
                                                 country == "Afghanistan" & date_target < as.Date("2019-09-28") ~ TRUE,
                                                 country == "Mexico" & date_target < as.Date("2018-07-01") ~ TRUE,
                                                 TRUE ~ FALSE)) %>%
      # remove polls after last election
      filter(target_before_last_elex) %>%
      filter(days_diff_abs < less_than_days_diff) %>%
      # remove Zimbabwe's 2013 election
      filter(!(country == "Zimbabwe" & year(date) == 2013))

    train_data_polls

  }

}

#' Create test data
create_test_data <- function(senti_targets_covars, choose_type = "election"){

  # Filter last election for each country
  senti_targets_covars %>%
    mutate(id = row_number()) %>%
    filter(type == choose_type) %>%
    group_by(country) %>%
    filter(date_target == max(date_target)) %>%
    ungroup()

}


