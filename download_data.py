# download_data.R
# -----------------------------------------------------------------------------
# Author:             Albert Kuo
# Date last modified: Oct 30, 2020
#
# Download NBA data using NBA API https://github.com/swar/nba_api

# Modules
import nba_api
from nba_api.stats.static import teams

nba_teams = teams.get_teams()

# Select the dictionary for the Pacers, which contains their team ID
pacers = [team for team in nba_teams if team['abbreviation'] == 'IND'][0]
pacers_id = pacers['id']
print(f'pacers_id: {pacers_id}')


# Query for the last regular season game where the Pacers were playing
from nba_api.stats.endpoints import leaguegamefinder
from nba_api.stats.library.parameters import SeasonAll
from nba_api.stats.library.parameters import SeasonType


print(pacers_id)
gamefinder = leaguegamefinder.LeagueGameFinder(team_id_nullable=pacers_id,
                            season_type_nullable=SeasonType.regular)  

games_dict = gamefinder.get_normalized_dict()
games = games_dict['LeagueGameFinderResults']
game = games[0]
game_id = game['GAME_ID']
game_matchup = game['MATCHUP']

print(f'Searching through {len(games)} game(s) for the game_id of {game_id} where {game_matchup}')

# Play by play data
from nba_api.stats.endpoints import playbyplay
print(game_id)
df = playbyplay.PlayByPlay(game_id).get_data_frames()[0]

df.head() # just looking at the head of the data
