# main.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Oct 30, 2020
#
# Main scripts for analysis


# Packages
library(reticulate)
library(here)
source_python(here("./code/download_data.py")) # Call Python script to use NBA API

# Download data
game_ids = get_game_ids()
game_ids_regular = game_ids[1]
game_ids_playoffs = game_ids[2]

# If there are new game IDs, download their data
# download_ids()
# download_playbyplay(game_ids)
