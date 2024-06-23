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
    state.player ||= { x: 640, y: 40, w: 50, h: 50, speed: 5, health: 10, powerups: [] }
    state.bullets ||= []
    state.enemy_bullets ||= []
    state.enemies ||= []
    state.wave ||= 1
    state.score ||= 0
    state.enemy_spawn_timer ||= 60
    state.player_hit_cooldown ||= 0
    state.explosions ||= []
    state.powerups ||= []
    state.powerup_spawn_timer ||= 600  # Spawn a powerup every 10 seconds
    state.screen_width ||= 1280
    state.screen_height ||= 720
    state.enemy_types ||= initialize_enemy_types
    state.game_over ||= false
    initialize_starfield
  end

  def input
    if state.game_over
      restart_game if inputs.keyboard.key_down.r
      return
    end

    # Speed powerup
    if state.player.powerups.include?(:speed)
      state.player.speed = 10
    else
      state.player.speed = 5
    end


    # Player movement
    state.player.x -= state.player.speed if inputs.keyboard.key_held.left
    state.player.x += state.player.speed if inputs.keyboard.key_held.right
    state.player.y -= state.player.speed if inputs.keyboard.key_held.down
    state.player.y += state.player.speed if inputs.keyboard.key_held.up

    # Keep player within screen bounds
    state.player.x = state.player.x.clamp(0, state.screen_width - state.player.w)
    state.player.y = state.player.y.clamp(0, state.screen_height - state.player.h)

    # Shooting
    if inputs.keyboard.key_down.space
      fire_player_bullets
    end
  end

  def calc
    update_starfield
    update_explosions
    return if state.game_over
    move_bullets
    move_enemy_bullets
    move_enemies
    move_powerups
    spawn_enemies
    spawn_powerups
    check_collisions
    check_player_enemy_collisions
    check_player_enemy_bullet_collisions
    check_player_powerup_collisions
    increase_difficulty
    check_game_over
  end

  def render
    # Set background to black
    outputs.solids << [0, 0, state.screen_width, state.screen_height, 0, 0, 0]
    render_starfield
    unless state.game_over
      render_player
      render_bullets
      render_enemy_bullets
      render_enemies
      render_explosions
      render_powerups
      render_ui
      render_player_health
    else
      render_explosions
      render_game_over
    end
  end

  def move_bullets
    state.bullets.each do |bullet|
      bullet.x += Math.cos(bullet.angle * Math::PI / 180) * bullet.speed
      bullet.y += Math.sin(bullet.angle * Math::PI / 180) * bullet.speed
    end
    state.bullets.reject! { |bullet| bullet.y > state.screen_height || bullet.x < 0 || bullet.x > state.screen_width }
  end

  def move_enemy_bullets
    state.enemy_bullets.each { |bullet| bullet.y -= bullet.speed }
    state.enemy_bullets.reject! { |bullet| bullet.y < 0 }
  end

  def move_enemies
    state.enemies.each { |enemy| enemy.move }
    state.enemies.reject! { |enemy| enemy.y < 0 }
  end

  def move_powerups
    state.powerups.each { |powerup| powerup.y -= 1 }
    state.powerups.reject! { |powerup| powerup.y < 0 }
  end

  def spawn_enemies
    state.enemy_spawn_timer -= 1
    if state.enemy_spawn_timer <= 0
      spawn_enemy
      state.enemy_spawn_timer = 60 - (state.wave * 2)
    end
  end

  def spawn_enemy
    enemy_type = state.enemy_types.sample
    spawn_width = [state.screen_width / 4 * (state.wave / 5.0), state.screen_width].min
    spawn_x = (state.screen_width - spawn_width) / 2 + rand(spawn_width)
    state.enemies << Enemy.new(spawn_x, state.screen_height, enemy_type)
  end

  def spawn_powerups
    state.powerup_spawn_timer -= 1
    if state.powerup_spawn_timer <= 0
      spawn_powerup
      state.powerup_spawn_timer = 600
    end
  end

  def spawn_powerup
    powerup_types = [
      { type: :multi_shot, sprite: 'sprites/square/blue.png' },
      { type: :health, sprite: 'sprites/square/green.png' },
      { type: :speed, sprite: 'sprites/square/red.png' }
    ]
    # select a random powerup
    random_powerup = powerup_types.sample
    state.powerups << { x: rand(state.screen_width), y: state.screen_height, w: 40, h: 40, type: random_powerup[:type], sprite: random_powerup[:sprite] }
  end

  def create_explosion(entity)
    state.explosions << { x: entity.x + entity.w / 2, y: entity.y + entity.h / 2, width: 10, height: 10, opacity: 255, age: 0 }
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

  def check_player_powerup_collisions
    state.powerups.reject! do |powerup|
      if state.player.intersect_rect?(powerup)
        apply_powerup(powerup)
        true
      end
    end
  end

  def check_game_over
    if state.player.health <= 0
      state.game_over = true
      state.enemies.each { |enemy| create_explosion(enemy) }
      state.enemies.clear
    end
  end

  def check_player_enemy_collisions
    state.enemies.reject! do |enemy|
      if state.player.intersect_rect?(enemy)
        if state.player_hit_cooldown <= 0
          state.player.health -= 1
          state.player_hit_cooldown = 60
        end
        create_explosion(enemy)
        true
      end
    end
    state.player_hit_cooldown -= 1 if state.player_hit_cooldown > 0
  end

  def check_player_enemy_bullet_collisions
    state.enemy_bullets.reject! do |bullet|
      if state.player.intersect_rect?(bullet)
        if state.player_hit_cooldown <= 0
          state.player.health -= 1
          state.player_hit_cooldown = 60
        end
        create_explosion(bullet)
        true
      end
    end
  end

  def apply_powerup(powerup)
    if powerup[:type] == :health
      state.player.health = 10
    else
      state.player.powerups << powerup[:type]
      state.player.powerups.uniq!
    end
  end

  def fire_player_bullets
    if state.player.powerups.include?(:multi_shot)
      [-30, 0, 30].each do |angle_offset|
        state.bullets << { x: state.player.x + state.player.w / 2, y: state.player.y + state.player.h, w: 5, h: 10, speed: 10, angle: 90 + angle_offset }
      end
    else
      state.bullets << { x: state.player.x + state.player.w / 2, y: state.player.y + state.player.h, w: 5, h: 10, speed: 10, angle: 90 }
    end
  end

  def update_explosions
    state.explosions.each do |explosion|
      explosion.width += 15
      explosion.height += 15
      explosion.y += 5
      explosion.age += 1.5
    end
    state.explosions.reject! { |explosion| explosion.age > 25 }
  end

  def increase_difficulty
    if state.score > state.wave * 1000
      state.wave += 1
    end
  end

  def update_starfield
    state.starfield.each_with_index do |layer, layer_index|
      layer.each do |star|
        star.y -= star.speed
        if star.y < 0
          star.y = state.screen_height
          star.x = rand(state.screen_width)
        end
      end
    end
  end

  def render_game_over
    outputs.labels << [state.screen_width / 2, state.screen_height / 2 + 50, "You lose!", 5, 1, 255, 0, 0]
    outputs.labels << [state.screen_width / 2, state.screen_height / 2, "Final Score: #{state.score}", 3, 1, 255, 255, 0]
    outputs.labels << [state.screen_width / 2, state.screen_height / 2 - 50, "Press 'R' to restart", 2, 1, 255, 255, 255]
  end

  def render_starfield
    outputs.sprites << state.starfield.flatten.map do |star|
      [star.x, star.y, star[:size], star[:size], 'sprites/circle/white.png', 0, star.alpha]
    end
  end

  def render_player
    outputs.sprites << [state.player.x, state.player.y, state.player.w, state.player.h, 'sprites/triangle/equilateral/orange.png']
  end

  def render_bullets
    outputs.solids << state.bullets.map { |b| [b.x, b.y, b.w, b.h, 255, 255, 0] }
  end

  def render_enemy_bullets
    outputs.solids << state.enemy_bullets.map { |b| [b.x, b.y, b.w, b.h, 255, 0, 0] }
  end

  def render_enemies
    outputs.sprites << state.enemies.map { |e| [e.x, e.y, e.w, e.h, e.sprite, e.angle] }
  end

  def render_explosions
    outputs.sprites << state.explosions.map do |e|
      frame = (e.age / 4).to_i % 7  # Cycle through 7 frames (0-6)
      [
        e.x - e.width / 2,
        e.y - e.height / 2,
        e.width,
        e.height,
        "sprites/misc/explosion-#{frame}.png",
        0,
        e.opacity,
        255,
        128,
        0
      ]
    end
  end

  def render_powerups
    outputs.sprites << state.powerups.map do |powerup|
      [powerup.x, powerup.y, powerup.w, powerup.h, powerup.sprite, 0, 255]
    end
  end

  def render_ui
    outputs.labels << { x: 10, y: 710, text: "Score: #{state.score}", size_enum: 1, alignment_enum: 0, r: 255, g: 255, b: 255 }
    outputs.labels << { x: 21, y: 680, text: "Wave: #{state.wave}", size_enum: 1, alignment_enum: 0, r: 255, g: 255, b: 255 }
  end

  def render_player_health
    10.times do |i|
      color = i < state.player.health ? [255, 0, 0] : [100, 100, 100]
      outputs.solids << [state.screen_width - 20 - (i * 30), 700, 20, 20, *color]
    end
  end

  def initialize_enemy_types
    [
      { name: :basic, sprite: 'sprites/circle/red.png', health: 1, speed: 2, score_value: 300, angle: -90, shoot_rate: 300 },
      { name: :tough, sprite: 'sprites/circle/blue.png', health: 3, speed: 1, score_value: 200, angle: -90, shoot_rate: 600 },
      { name: :fast, sprite: 'sprites/circle/green.png', health: 1, speed: 4, score_value: 100, angle: -90, shoot_rate: 0 }
    ]
  end

  def initialize_starfield
    state.starfield_layers ||= 4
    state.starfield ||= state.starfield_layers.times.map do |layer|
      100.times.map do
        {
          x: rand(state.screen_width),
          y: rand(state.screen_height),
          speed: (layer + 1) * 0.5,
          size: (layer + 1) * 2,
          alpha: 255 / (state.starfield_layers - layer)
        }
      end
    end
  end

  def restart_game
    state.player = { x: 640, y: 40, w: 50, h: 50, speed: 5, health: 10, powerups: [] }
    state.bullets = []
    state.enemy_bullets = []
    state.enemies = []
    state.powerups = []
    state.wave = 1
    state.score = 0
    state.enemy_spawn_timer = 60
    state.powerup_spawn_timer = 600
    state.player_hit_cooldown = 0
    state.explosions = []
    state.game_over = false
  end
end

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

$game = Game.new

def tick args
  $game.args = args
  $game.tick
end
