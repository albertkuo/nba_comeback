# plot_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 5, 2020
#
# Plot heatmap
library(ggplot2)
library(plotly)

plot_data = function(df){
  p = ggplot(df, aes(-minute, diff, fill = prob_win, text = text)) +
    geom_tile() +
    facet_grid(. ~ quarter, scales = "free_x", space = "free_x") +
    scale_x_continuous(breaks = c(seq(-12, 0, by = 2)),
                       labels = c(seq(12, 0, by = -2))) +
    scale_y_continuous(breaks = seq(-30, 30, by = 5),
                       labels = c(seq(-30, 0, by = 5),
                                  paste0("+", seq(5, 30, by = 5))),
                       limits = c(-30, 30)) +
    scale_fill_gradient2(midpoint = 0.5,
                         low = "#d63a3a", mid = "#ffd700", high = "#33aa00") +
    labs(subtitle = "Quarters",
         x = "Minutes left",
         y = "Score margin",
         fill = "Probability of win") +
    theme_bw() +
    theme(plot.subtitle = element_text(hjust = 0.5),
          axis.text.x = element_text(angle = 90, hjust = 1),
          strip.background = element_blank(),
          panel.border = element_blank(),
          panel.spacing = unit(0, "mm"),
          panel.grid = element_blank())

  return(p)
}
