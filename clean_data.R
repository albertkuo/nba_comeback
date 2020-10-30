# clean_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Oct 30, 2020
#
# Clean NBA play-by-play data for analysis

# Packages
library(reticulate)
source_python("download_data.py") # Call Python script to use NBA API


# If there are new game IDs, download their data
# download_ids()
# download_playbyplay(game_ids)
