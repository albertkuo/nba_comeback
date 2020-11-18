# main.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 8, 2020
#
# Main script for analysis


# Packages
library(reticulate)
library(here)
library(tictoc)

# Download data
source_python(here("./code/download_data.py")) # Call Python script to use NBA API

## Get game IDs
game_ids = get_game_ids() # function in download_data.py
game_ids_regular = game_ids[[1]]
game_ids_playoffs = game_ids[[2]]
game_ids_all = c(game_ids_regular, game_ids_playoffs)

## Get game IDs previously downloaded already
if(file.exists(here("./data/game_ids.txt"))){
  game_ids_previous = readLines(here("./data/game_ids.txt"))
} else {
  game_ids_previous = c()
}

## Only download new game IDs
game_ids_regular = setdiff(game_ids_regular, game_ids_previous)
game_ids_playoffs = setdiff(game_ids_playoffs, game_ids_previous)
message("Downloading ", length(game_ids_regular), " regular season games and ",
        length(game_ids_playoffs), " playoff games")

## Get play by play for every regular season game
game_id = "0041000206" # Note game_id = "1421200014" is empty
empty_games = 0
games_regular = vector(mode = "list", length = length(game_ids_regular))
tic("Download regular season games")
for(i in seq_along(game_ids_regular)){
  if(i %% 100 == 0){
    message("Downloaded ", i, " out of ", length(game_ids_regular), " games...")
  }

  game_id = game_ids_regular[[i]]
  games_regular[[i]] = tryCatch({get_play_by_play(game_id)}, error = function(e) return(NULL))

  # Count number of games that were not found
  if(is.null(games_regular[[i]]))
    empty_games = empty_games + 1
}
toc()
message("Failed to download ", empty_games, " out of ", length(game_ids_regular), " regular season games")
if(file.exists(here("./data/games_regular.rds"))){
  games_regular_previous = readRDS(here("./data/games_regular.rds"))
  games_regular = bind_rows(games_regular_previous, games_regular)
  saveRDS(games_regular, here("./data/games_regular.rds"))
} else {
  saveRDS(games_regular, here("./data/games_regular.rds"))
}

## Get play by play for every playoffs game
empty_games = 0
games_playoffs = vector(mode = "list", length = length(game_ids_playoffs))
tic("Download playoff games")
for(i in seq_along(game_ids_playoffs)){
  if(i %% 100 == 0){
    message("Downloaded ", i, " out of ", length(game_ids_playoffs), " games...")
  }

  game_id = game_ids_playoffs[[i]]
  games_playoffs[[i]] = tryCatch({get_play_by_play(game_id)}, error = function(e) return(NULL))

  # Count number of games that were not found
  if(is.null(games_playoffs[[i]]))
    empty_games = empty_games + 1
}
toc()
message("Failed to download ", empty_games, " out of ", length(game_ids_playoffs), " playoff games")
if(file.exists(here("./data/games_playoffs.rds"))){
  games_regular_previous = readRDS(here("./data/games_playoffs.rds"))
  games_regular = bind_rows(games_regular_previous, games_regular)
  saveRDS(games_regular, here("./data/games_playoffs.rds"))
} else {
  saveRDS(games_regular, here("./data/games_playoffs.rds"))
}

## Save game IDs that have been downloaded (or attempted to download)
game_ids_scraped = c(game_ids_previous, game_ids_regular, game_ids_playoffs)
write(game_ids_scraped, here("./data/game_ids.txt"))

## Save game IDs that failed to download
if(file.exists(here("./data/game_ids_failed.txt"))){
  game_ids_failed = readLines(here("./data/game_ids_failed.txt"))
  game_ids_failed = c(game_ids_failed,
                      game_ids_regular[which(sapply(games_regular, function(x) is.null(x)))],
                      game_ids_playoffs[which(sapply(games_playoffs, function(x) is.null(x)))])
  write(game_ids_failed, here("./data/game_ids_failed.txt"))
} else {
  game_ids_failed = c(game_ids_regular[which(sapply(games_regular, function(x) is.null(x)))],
                      game_ids_playoffs[which(sapply(games_playoffs, function(x) is.null(x)))])
  write(game_ids_failed, here("./data/game_ids_failed.txt"))
}

# Clean data
source(here("./code/clean_data.R"))

## Read in games
games_playoffs = readRDS(here("./data/games_playoffs.rds"))
games_regular = readRDS(here("./data/games_regular.rds"))

## Clean up columns
tic("Clean playoff games") # 20 sec
games_playoffs_clean = lapply(games_playoffs, clean_data)
toc()
saveRDS(games_playoffs_clean, here("./data/games_playoffs_clean.rds"))

tic("Clean regular season games") # 3 min
games_regular_clean = lapply(games_regular, clean_data)
toc()
saveRDS(games_regular_clean, here("./data/games_regular_clean.rds"))

## Summarize data
games_playoffs_clean = readRDS(here("./data/games_playoffs_clean.rds"))
games_regular_clean = readRDS(here("./data/games_regular_clean.rds"))

games_playoffs_summ = summarize_data(games_playoffs_clean)
games_regular_summ = summarize_data(games_regular_clean)

## Plot data
source(here("./code/plot_data.R"))
p = plot_data(games_playoffs_summ)
ggplotly(p, tooltip = "text")

p = plot_data(games_regular_summ)
ggplotly(p, tooltip = "text")

## Smooth probabilities monotonically in both directions
source(here("./code/smooth_data.R"))
tic() # ~2 min, lots of print statements
games_playoffs_smooth = smooth_data(games_playoffs_summ)
toc()
games_playoffs_smooth = symmetrize_data(games_playoffs_smooth)

p = plot_data(games_playoffs_smooth %>% mutate(prob_win = prob_win_smooth))
ggplotly(p, tooltip = "text")

tic() # ~2 min, lots of print statements
games_regular_smooth = smooth_data(games_regular_summ)
toc()
games_regular_smooth = symmetrize_data(games_regular_smooth)

p = plot_data(games_regular_smooth %>% mutate(prob_win = prob_win_smooth))
ggplotly(p, tooltip = "text")

## Model-based probabilities
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
