# Simple Shooter Game in DragonRuby
require_relative 'game'
require_relative 'enemy'
require_relative 'bullet'
require_relative 'audio_manager'
require_relative 'bullet_manager'
require_relative 'input_handler'
require_relative 'render_manager'

$game = Game.new

def tick args
  $game.args = args
  $game.tick
end
