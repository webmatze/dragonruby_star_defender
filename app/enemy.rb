class Enemy
  attr_accessor :x, :y, :w, :h, :speed, :health, :sprite, :angle, :score_value, :shoot_rate

  def initialize(x, y, type)
    @x = x
    @y = y
    @w = 40
    @h = 40
    @created_at_tick = $game.state.tick_count
    @speed = type[:speed] + ($game.state.wave * 0.1)
    @health = type[:health]
    @sprites = type[:sprites]
    @sprite_index = 0
    @animation_speed = 6 # Change sprite every 6 frames
    @frame_counter = 0
    @angle = type[:angle]
    @score_value = type[:score_value]
    @shoot_rate = type[:shoot_rate]
    @last_shot_time = 0
    @movement_pattern = method("move_#{type[:name]}")
  end

  def move
    @movement_pattern.call
    fire_bullet if can_shoot?
    animate
  end

  def hit
    @health -= 1
  end

  def to_h
    {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      path: current_sprite,
      angle: @angle
    }
  end

  private

  def animate
    @frame_counter += 1
    @sprite_index = (@frame_counter / @animation_speed) % @sprites.size
  end

  def current_sprite
    @sprites[@sprite_index]
  end

  def ticks_elapsed
    $game.state.tick_count - @created_at_tick
  end

  def move_basic
    @y -= @speed
  end

  def move_tough
    @y -= @speed
    @x += Math.sin(ticks_elapsed * 0.02) * 2
  end

  def move_fast
    @y -= @speed
    @x += Math.cos(ticks_elapsed * 0.2) * 3
  end

  def can_shoot?
    return false if @shoot_rate <= 0
    $game.state.tick_count - @last_shot_time >= @shoot_rate
  end

  def fire_bullet
    $game.enemy_bullet_manager.create_bullet(:straight, @x + @w / 2, @y, 270, speed: 5, color: [255, 0, 0])
    @last_shot_time = $game.state.tick_count
  end
end
