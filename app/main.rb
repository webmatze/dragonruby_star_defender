# Simple Shooter Game in DragonRuby

class Game
  attr_gtk

  def tick
    defaults
    input
    calc
    render
  end

  def defaults
    # Initialize game state
    state.player ||= { x: 640, y: 40, w: 50, h: 50, speed: 5 }
    state.bullets ||= []
    state.enemies ||= []
    state.wave ||= 1
    state.score ||= 0
    state.enemy_spawn_timer ||= 60
    state.player_hit_cooldown ||= 0
    state.explosions ||= []
    state.screen_width ||= 1280
    state.screen_height ||= 720
    state.enemy_types ||= initialize_enemy_types
  end

  def input
    # Player movement
    state.player.x -= state.player.speed if inputs.keyboard.key_held.left
    state.player.x += state.player.speed if inputs.keyboard.key_held.right

    # Shooting
    if inputs.keyboard.key_down.space
      state.bullets << { x: state.player.x + state.player.w / 2, y: state.player.y + state.player.h, w: 5, h: 10, speed: 10 }
    end
  end

  def calc
    move_bullets
    move_enemies
    spawn_enemies
    check_collisions
    update_explosions
    check_player_enemy_collisions
    increase_difficulty
  end

  def render
    clear_screen
    render_player
    render_bullets
    render_enemies
    render_explosions
    render_ui
  end

  def move_bullets
    state.bullets.each { |bullet| bullet.y += bullet.speed }
    state.bullets.reject! { |bullet| bullet.y > state.screen_height }
  end

  def move_enemies
    state.enemies.each { |enemy| enemy.move }
    state.enemies.reject! { |enemy| enemy.y < 0 }
  end

  def spawn_enemies
    state.enemy_spawn_timer -= 1
    if state.enemy_spawn_timer <= 0
      spawn_enemy
      state.enemy_spawn_timer = 60 - (state.wave * 2)
    end
  end

  def check_collisions
    state.bullets.reject! do |bullet|
      state.enemies.reject! do |enemy|
        if bullet.intersect_rect?(enemy)
          enemy.hit
          if enemy.health <= 0
            state.score += enemy.score_value
            create_explosion(enemy)
            true
          end
        end
      end
    end
  end

  def update_explosions
    state.explosions.each do |explosion|
      explosion.width += 15
      explosion.height += 15
      explosion.opacity -= 15
      explosion.y += 5
      explosion.age += 1.5
    end
    state.explosions.reject! { |explosion| explosion.age > 25 }
  end

  def check_player_enemy_collisions
    state.enemies.reject! do |enemy|
      if state.player.intersect_rect?(enemy)
        if state.player_hit_cooldown <= 0
          state.score -= 2
          state.score = 0 if state.score < 0
          state.player_hit_cooldown = 60
        end
        create_explosion(enemy)
        true
      end
    end
    state.player_hit_cooldown -= 1 if state.player_hit_cooldown > 0
  end

  def increase_difficulty
    if state.score > state.wave * 10
      state.wave += 1
    end
  end

  def clear_screen
    outputs.background_color = [0, 0, 0]
  end

  def render_player
    outputs.sprites << [state.player.x, state.player.y, state.player.w, state.player.h, 'sprites/triangle/equilateral/orange.png']
  end

  def render_bullets
    outputs.solids << state.bullets.map { |b| [b.x, b.y, b.w, b.h, 255, 255, 0] }
  end

  def render_enemies
    outputs.sprites << state.enemies.map { |e| [e.x, e.y, e.w, e.h, e.sprite, e.angle] }
  end

  def render_explosions
    outputs.sprites << state.explosions.map do |e|
      [e.x - e.width / 2, e.y - e.height / 2, e.width, e.height, 'sprites/misc/explosion-3.png', 0, e.opacity, 255, 128, 0]
    end
  end

  def render_ui
    outputs.labels << [1220, 710, "Score: #{state.score}", 1, 1, 255, 255, 255]
    outputs.labels << [1220, 680, "Wave: #{state.wave}", 1, 1, 255, 255, 255]
  end

  def spawn_enemy
    enemy_type = state.enemy_types.sample
    spawn_width = [state.screen_width / 4 * (state.wave / 5.0), state.screen_width].min
    spawn_x = (state.screen_width - spawn_width) / 2 + rand(spawn_width)
    state.enemies << Enemy.new(spawn_x, state.screen_height, enemy_type)
  end

  def create_explosion(entity)
    state.explosions << { x: entity.x + entity.w / 2, y: entity.y + entity.h / 2, width: 10, height: 10, opacity: 255, age: 0 }
  end

  def initialize_enemy_types
    [
      { name: :basic, sprite: 'sprites/circle/red.png', health: 1, speed: 2, score_value: 1, angle: -90 },
      { name: :tough, sprite: 'sprites/circle/blue.png', health: 3, speed: 1, score_value: 3, angle: -90 },
      { name: :fast, sprite: 'sprites/circle/green.png', health: 1, speed: 4, score_value: 2, angle: -90 }
    ]
  end
end

class Enemy
  attr_accessor :x, :y, :w, :h, :speed, :health, :sprite, :angle, :score_value

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
    @movement_pattern = method("move_#{type[:name]}")
  end

  def move
    @movement_pattern.call
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
end

$game = Game.new

def tick args
  $game.args = args
  $game.tick
end
