# Annotation size
# when text size
text_size <- 15
anno_size <- text_size*(5/14)

# Font
theme_font <- "Helvetica"

# Colour code
blue_colour <- "#0000FF"

#font_import()
#loadfonts()

# Theme
theme_devpublicopinion <- theme(axis.text = element_text(size = unit(text_size, "mm"),
                                                         family = theme_font, colour = "black"),
                                axis.title = element_text(size = unit(text_size, "mm"), family = theme_font),
                                #axis.title.y = element_blank(),
                                axis.ticks = element_blank()) +
  theme(plot.title = element_text(size = unit(text_size*1.5, "mm"), family = theme_font),
        plot.subtitle = element_text(size = unit(text_size, "mm"), family = theme_font),
        plot.caption=element_text(size = unit(text_size, "mm"), family = theme_font)) +
  theme(panel.background = element_blank(),
        plot.background = element_blank(),
        panel.grid.major = element_line(color = "gray50", size = 0.2)
  ) +
  theme(legend.position = "top",
        legend.text = element_text(family = theme_font, size = unit(text_size, "mm")),
        legend.title = element_text(family = theme_font, size = unit(text_size, "mm")),
        legend.key = element_blank()) +
  theme(strip.text = element_text(size = text_size-2),
        strip.background = element_blank(),
        axis.text = element_text(size = unit(text_size-2, "mm"))
  )
