# Simple Shooter Game in DragonRuby
require_relative 'game'
require_relative 'input_handler'
require_relative 'enemy'
require_relative 'audio_manager'

$game = Game.new

def tick args
  $game.args = args
  $game.tick
end
