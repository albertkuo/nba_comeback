# main.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 17, 2020
#
# Main script for analysis


# Packages
library(reticulate)
library(here)
library(tictoc)

# Download data
source(here("./code/clean_data.R"))
download_data() # wrapper for Python functions to download game IDs and play-by-play data

# Clean data
source(here("./code/clean_data.R"))

## Read in games
games_playoffs = readRDS(here("./data/games_playoffs.rds"))
games_regular = readRDS(here("./data/games_regular.rds"))

## Clean up columns
games_playoffs_clean = lapply(games_playoffs, clean_data) # 20 sec
saveRDS(games_playoffs_clean, here("./data/games_playoffs_clean.rds"))

games_regular_clean = lapply(games_regular, clean_data) # ~3 min
saveRDS(games_regular_clean, here("./data/games_regular_clean.rds"))

## Summarize data
games_playoffs_clean = readRDS(here("./data/games_playoffs_clean.rds"))
games_regular_clean = readRDS(here("./data/games_regular_clean.rds"))

games_playoffs_summ = summarize_data(games_playoffs_clean)
games_regular_summ = summarize_data(games_regular_clean)
games_overall_summ = summarize_data(bind_rows(games_playoffs_clean, games_regular_clean))

# Plot data
source(here("./code/plot_data.R"))

## Plot empirical data
p = plot_data(games_playoffs_summ)
ggplotly(p, tooltip = "text")

p = plot_data(games_regular_summ)
ggplotly(p, tooltip = "text")

p = plot_data(games_overall_summ)
ggplotly(p, tooltip = "text")

## Plot smoothed data
source(here("./code/smooth_data.R"))
games_playoffs_smooth = smooth_data(games_playoffs_summ) # ~2 min, lots of print statements
games_playoffs_smooth = symmetrize_data(games_playoffs_smooth)
p = plot_data(games_playoffs_smooth %>% mutate(prob_win = prob_win_smooth))
ggplotly(p, tooltip = "text")

games_regular_smooth = smooth_data(games_regular_summ) # ~3 min
games_regular_smooth = symmetrize_data(games_regular_smooth)
p = plot_data(games_regular_smooth %>% mutate(prob_win = prob_win_smooth))
ggplotly(p, tooltip = "text")

games_overall_smooth = smooth_data(games_overall_summ) # ~3 min
games_overall_smooth = symmetrize_data(games_overall_smooth)
p = plot_data(games_overall_smooth %>% mutate(prob_win = prob_win_smooth))
ggplotly(p, tooltip = "text")


## Plot model-based probabilities (WIP)
source(here("./code/model_data.R"))
y_model = sapply(x, function(x) model_prob(x, score_margin))

plot_dt = tibble(x = x,
                 y = y,
                 y_smooth = y_smooth,
                 y_model = y_model)
plot_dt %>%
  ggplot(aes(x = x, y = y)) +
  geom_point() +
  geom_line(aes(y = y_smooth), color = "blue") +
  geom_line(aes(y = y_model), color = "red") +
  theme_bw()
