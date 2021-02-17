#### Solve circles going beyond region

scrape_find_radius <- left_join(scrape_regions_line, gpw_bng,
                                by = c("gpw_id", "countrynm", "gpw_smallest", "name1", "name2", "name3", "name4", "name5", "name6")) %>%
  filter(name_1 == "Ondo")

# Kano, 

dist_lines <- st_as_sf(scrape_find_radius$geometry_line)
dist_points <- st_as_sf(scrape_find_radius$geometry_point)

# Calculate distances, in metres
distance <- st_distance(dist_lines, dist_points,
                        by_element = TRUE,
                        which = "Euclidean"
)

plot(dist_points)

plot(dist_lines)
