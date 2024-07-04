class Level
  attr_reader :available_time, :possible_enemies, :initial_player_health, :possible_powerups, :max_waves, :powerup_spawn_timer, :enemy_spawn_timer, :minimum_points_to_spawn_powerup
  attr_accessor :time_remaining

  def initialize(available_time:, possible_enemies:, initial_player_health:, possible_powerups:, max_waves:, powerup_spawn_timer:, enemy_spawn_timer:, minimum_points_to_spawn_powerup:)
    @available_time = available_time
    @time_remaining = available_time
    @possible_enemies = possible_enemies
    @initial_player_health = initial_player_health
    @possible_powerups = possible_powerups
    @max_waves = max_waves
    @powerup_spawn_timer = powerup_spawn_timer
    @enemy_spawn_timer = enemy_spawn_timer
    @minimum_points_to_spawn_powerup = minimum_points_to_spawn_powerup
  end
end
