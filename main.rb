require_relative 'game.rb'

main_game = Game.new(:ai)
main_game.set_games(5)
main_game.start()