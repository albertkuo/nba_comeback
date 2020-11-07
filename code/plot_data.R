# plot_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 7, 2020
#
# Plot heatmap
library(ggplot2)
library(plotly)

plot_data = function(df){
  # Quarter facet labels
  quarter_labels = paste("Quarter", 1:4)
  names(quarter_labels) = 1:4

  # Plot
  p = ggplot(df, aes(x = -minute, y = diff, fill = prob_win, text = text)) +
    geom_raster(hjust = 0) +
    facet_grid(. ~ quarter, scales = "free_x",
               labeller = labeller(quarter = quarter_labels),
               switch = "x") +
    scale_x_continuous(breaks = c(seq(-11, 0, by = 1)),
                       labels = c(seq(11, 0, by = -1)),
                       expand = c(0, 0)) +
    scale_y_continuous(breaks = seq(-30, 30, by = 5),
                       labels = c(seq(-30, 0, by = 5),
                                  paste0("+", seq(5, 30, by = 5))),
                       limits = c(-30, 30),
                       expand = c(0, 0)) +
    scale_fill_gradient2(midpoint = 0.5,
                         low = "#d63a3a", mid = "#ffd700", high = "#33aa00") +
    labs(x = "Time Left",
         y = "Score Margin",
         fill = "Probability of win") +
    theme_bw() +
    theme(plot.subtitle = element_text(hjust = 0.5),
          strip.background = element_blank(),
          strip.placement = "outside",
          # strip.background = element_rect(fill=NA,colour="grey50"),
          panel.border = element_blank(),
          panel.spacing = unit(0.2, "mm"),
          panel.grid = element_blank())

  return(p)
}
