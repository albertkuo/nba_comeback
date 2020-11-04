# main.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Nov 1, 2020
#
# Main script for analysis


# Packages
library(reticulate)
library(here)
library(tictoc)
source_python(here("./code/download_data.py")) # Call Python script to use NBA API

# Download data
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
saveRDS(games_regular, here("./data/games_regular.rds"))

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
saveRDS(games_playoffs, here("./data/games_playoffs.rds"))


# Save game IDs that have been scraped (or attempted to)
game_ids_scraped = c(game_ids_previous, game_ids_regular, game_ids_playoffs)
write(game_ids_scraped, here("./data/game_ids.txt"))

# Save game IDs that failed to scrape
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

