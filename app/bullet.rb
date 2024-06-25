class Bullet
  attr_accessor :x, :y, :w, :h, :speed, :angle

  def initialize(x, y, w, h, speed, angle)
    @x = x
    @y = y
    @w = w
    @h = h
    @speed = speed
    @angle = angle
  end

  def update
    move
  end

  def move
    @x += Math.cos(@angle * Math::PI / 180) * @speed
    @y += Math.sin(@angle * Math::PI / 180) * @speed
  end

  def off_screen?(screen_width, screen_height)
    @x < 0 || @x > screen_width || @y < 0 || @y > screen_height
  end

  def intersect_rect?(rect)
    [@x, @y, @w, @h].intersect_rect?(rect)
  end
end

class StraightBullet < Bullet
  # Uses default behavior from Bullet
end

class AngledBullet < Bullet
  # Uses default behavior from Bullet
end

class SeekingBullet < Bullet
  def initialize(x, y, w, h, speed, angle, target)
    super(x, y, w, h, speed, angle)
    @target = target
    @turn_speed = 2 # Adjust as needed
  end

  def move
    if @target && @target.health > 0
      dx = @target.x - @x
      dy = @target.y - @y
      target_angle = Math.atan2(dy, dx) * 180 / Math::PI
      angle_diff = ((target_angle - @angle + 540) % 360) - 180
      @angle += angle_diff.clamp(-@turn_speed, @turn_speed)
    else
      new_target
    end
    super
  end

  def nearest_enemy
    $game.state.enemies.select { |enemy| enemy.y > @y }
                 .min_by { |enemy| (enemy.x - @x).abs + (enemy.y - @y).abs }
  end

  def new_target
    @target = nearest_enemy
  end
end
