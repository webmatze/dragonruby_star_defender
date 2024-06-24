class Enemy
  attr_accessor :x, :y, :w, :h, :speed, :health, :sprite, :angle, :score_value, :shoot_rate

  def initialize(x, y, type)
    @x = x
    @y = y
    @w = 40
    @h = 40
    @speed = type[:speed] + ($game.state.wave * 0.1)
    @health = type[:health]
    @sprite = type[:sprite]
    @angle = type[:angle]
    @score_value = type[:score_value]
    @shoot_rate = type[:shoot_rate]
    @last_shot_time = 0
    @movement_pattern = method("move_#{type[:name]}")
  end

  def move
    @movement_pattern.call
    fire_bullet if can_shoot?
  end

  def hit
    @health -= 1
  end

  private

  def move_basic
    @y -= @speed
  end

  def move_tough
    @y -= @speed
    @x += Math.sin($game.state.tick_count * 0.1) * 2
  end

  def move_fast
    @y -= @speed
    @x += Math.cos($game.state.tick_count * 0.2) * 3
  end

  def can_shoot?
    return false if @shoot_rate <= 0
    $game.state.tick_count - @last_shot_time >= @shoot_rate
  end

  def fire_bullet
    $game.state.enemy_bullets << { x: @x + @w / 2, y: @y, w: 5, h: 10, speed: 5 }
    @last_shot_time = $game.state.tick_count
  end
end
