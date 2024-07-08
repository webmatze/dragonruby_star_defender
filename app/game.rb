class Game
  attr_gtk

  def tick
    defaults
    input_handler.handle_input
    calc unless state.paused
    render_manager.render
    audio_manager.play_background_music if state.tick_count == 1
  end

  def defaults
    # Initialize game state
    state.enemy_types ||= initialize_enemy_types
    state.powerup_types ||= initialize_powerup_types
    state.level_index ||= 0
    state.levels ||= initialize_levels
    state.current_level ||= state.levels[state.level_index]
    state.enemy_spawn_timer ||= state.current_level.enemy_spawn_timer
    state.powerup_spawn_timer ||= state.current_level.powerup_spawn_timer
    state.player ||= { x: 640, y: 40, w: 50, h: 50, speed: 5, health: state.current_level.initial_player_health, powerups: {} }
    state.shield ||= { x: 0, y: 0, w: 0, h: 0, active: false }
    state.enemies ||= []
    state.wave ||= 1
    state.score ||= 0
    state.explosions ||= []
    state.powerups ||= []
    state.screen_width ||= 1280
    state.screen_height ||= 720
    state.game_over ||= false
    state.primary_weapon_cooldown ||= 0
    initialize_starfield
  end

  def calc
    update_starfield
    update_explosions
    return if state.game_over
    move_shield
    bullet_manager.update
    enemy_bullet_manager.update
    update_powerups
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
    update_player_speed
    update_level_timer
    update_primary_weapon_cooldown
  end

  def initialize_enemy_types
    [
      { name: :basic, sprites: ['sprites/circle/red.png'], health: 2, speed: 2, score_value: 300, angle: -90, shoot_rate: 300 },
      { name: :tough, sprites: ['sprites/enemy-1/sprite_0.png', 'sprites/enemy-1/sprite_1.png', 'sprites/enemy-1/sprite_2.png', 'sprites/enemy-1/sprite_3.png'], health: 3, speed: 1.5, score_value: 200, angle: -90, shoot_rate: 600 },
      { name: :fast, sprites: ['sprites/circle/green.png'], health: 1, speed: 4, score_value: 100, angle: -90, shoot_rate: 0 }
    ]
  end

  def initialize_powerup_types
    [
      { type: :multi_shot, sprite: 'sprites/powerups/powerups-2.png', max_level: 3, priority: 2 },
      { type: :health, sprite: 'sprites/powerups/powerups-4.png', max_level: 1, priority: 0 },
      { type: :speed, sprite: 'sprites/powerups/powerups-3.png', max_level: 3, priority: 1 },
      { type: :shield, sprite: 'sprites/powerups/powerups-1.png', max_level: 2, priority: 3 },
      { type: :seeking, sprite: 'sprites/hexagon/indigo.png', max_level: 2, priority: 4 }
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

  def initialize_levels
    [
      Level.new(
        available_time: 60*60*5, # 5 minutes
        possible_enemies: select_enemies([:basic, :tough]),
        initial_player_health: 3,
        possible_powerups: select_powerups([:multi_shot, :health, :speed]),
        max_waves: 3,
        powerup_spawn_timer: 600,
        enemy_spawn_timer: 60,
        minimum_points_to_spawn_powerup: 2500
      )
    ]
  end

  def select_powerups(powerup_types)
    state.powerup_types.select { |powerup| powerup_types.include?(powerup[:type]) }
  end

  def select_enemies(enemy_types)
    state.enemy_types.select { |enemy| enemy_types.include?(enemy[:name]) }
  end

  def audio_manager
    @audio_manager ||= AudioManager.new(args)
  end

  def input_handler
    @input_handler ||= InputHandler.new(self)
  end

  def bullet_manager
    @bullet_manager ||= BulletManager.new(self)
  end

  def enemy_bullet_manager
    @enemy_bullet_manager ||= BulletManager.new(self)
  end

  def render_manager
    @render_manager ||= RenderManager.new(self)
  end

  def move_enemies
    state.enemies.each { |enemy| enemy.move }
    state.enemies.reject! { |enemy| enemy.y < 0 }
  end

  def move_powerups
    state.powerups.each { |powerup| powerup.y -= 1 }
    state.powerups.reject! { |powerup| powerup.y < 0 }
  end

  def move_shield
    if state.player.powerups.include?(:shield)
      state.shield.x = state.player.x + state.player.w / 2 - state.shield.w / 2
      state.shield.y = state.player.y + state.player.h / 2 - state.shield.h / 2
      state.shield.w = [state.player.w, state.player.h].max * 1.8
      state.shield.h = [state.player.w, state.player.h].max * 1.8
      state.shield.active = true
    else
      state.shield.active = false
    end
  end

  def spawn_enemies
    state.enemy_spawn_timer -= 1
    if state.enemy_spawn_timer <= 0
      spawn_enemy
      state.enemy_spawn_timer = state.current_level.enemy_spawn_timer
    end
  end

  def spawn_enemy
    enemy_type = state.current_level.possible_enemies.sample
    spawn_width = [state.screen_width / 3 * (state.wave / 3.0), state.screen_width].min
    spawn_x = (state.screen_width - spawn_width) / 2 + rand(spawn_width)
    state.enemies << Enemy.new(spawn_x, state.screen_height, enemy_type)
  end

  def spawn_powerups
    state.powerup_spawn_timer -= 1
    if state.powerup_spawn_timer <= 0
      spawn_powerup
      state.powerup_spawn_timer = state.current_level.powerup_spawn_timer
    end
  end

  def spawn_powerup
    return unless state.score >= state.current_level.minimum_points_to_spawn_powerup

    powerup = state.current_level.possible_powerups.sample
    state.powerups << {
      x: rand(state.screen_width),
      y: state.screen_height,
      w: 64,
      h: 64,
      type: powerup[:type],
      sprite: powerup[:sprite],
      max_level: powerup[:max_level],
      priority: powerup[:priority]
    }
  end

  def create_explosion(entity)
    state.explosions << { x: entity.x + entity.w / 2, y: entity.y + entity.h / 2, width: 10, height: 10, opacity: 255, age: 0 }
  end

  def check_collisions
    bullet_manager.bullets.reject! do |bullet|
      bullet_hit = false
      state.enemies.reject! do |enemy|
        if bullet.intersect_rect?(enemy)
          enemy.hit
          audio_manager.bullet_hit
          bullet_hit = true
          if enemy.health <= 0
            state.score += enemy.score_value
            create_explosion(enemy)
            true
          end
        end
      end
      bullet_hit
    end
  end

  def check_player_powerup_collisions
    state.powerups.reject! do |powerup|
      if state.player.intersect_rect?(powerup)
        apply_powerup(powerup)
        audio_manager.powerup_pickup
        true
      end
    end
  end

  def check_game_over
    if state.player.health <= 0 || state.current_level.time_remaining <= 0
      state.game_over = true
      state.enemies.each { |enemy| create_explosion(enemy) }
      state.enemies.clear
      audio_manager.game_over
      audio_manager.stop_background_music
    end
  end

  def check_player_enemy_collisions
    state.enemies.reject! do |enemy|
      if state.shield.active
        if state.shield.intersect_rect?(enemy)
          create_explosion(enemy)
          audio_manager.shield_hit
          true
        end
      else
        if state.player.intersect_rect?(enemy)
          if state.player_hit_cooldown <= 0
            state.player.health -= 1
            state.player_hit_cooldown = 60
            audio_manager.player_hit
          end
          create_explosion(enemy)
          true
        end
      end
    end
    state.player_hit_cooldown -= 1 if state.player_hit_cooldown > 0
  end

  def check_player_enemy_bullet_collisions
    enemy_bullet_manager.bullets.reject! do |bullet|
      if state.shield.active
        if bullet.intersect_rect?(state.shield)
          create_explosion(bullet)
          audio_manager.shield_hit
          true
        end
      else
        if bullet.intersect_rect?(state.player)
          if state.player_hit_cooldown <= 0
            state.player.health -= 1
            state.player_hit_cooldown = 60
            audio_manager.player_hit
          end
          create_explosion(bullet)
          true
        end
      end
    end
  end

  def apply_powerup(powerup)
    if powerup[:type] == :health
      state.player.health = [state.player.health + 3, state.current_level.initial_player_health].min
      audio_manager.health_pickup
    else
      current_powerup = state.player.powerups[powerup[:type]]
      if current_powerup
        if current_powerup[:level] < powerup[:max_level]
          current_powerup[:level] += 1
          current_powerup[:health] = 3
        else
          current_powerup[:health] = [current_powerup[:health] + 2, 5].min
        end
      else
        state.player.powerups[powerup[:type]] = {
          type: powerup[:type],
          level: 1,
          health: 3,
          max_level: powerup[:max_level],
          priority: powerup[:priority]
        }
      end
    end
  end

  def update_powerups
    state.player.powerups.reject! { |_, powerup| powerup[:health] <= 0 }
  end

  def fire_primary_weapon
    return if state.primary_weapon_cooldown > 0

    active_weapon = state.player.powerups.values.max_by { |p| p[:priority] }
    case active_weapon&.[](:type)
    when :multi_shot
      angles = case active_weapon[:level]
               when 1 then [-30, 0, 30]
               when 2 then [-45, -15, 15, 45]
               when 3 then [-60, -30, 0, 30, 60]
               end
      angles.each do |angle_offset|
        bullet_manager.create_bullet(:angled, state.player.x + state.player.w / 2, state.player.y + state.player.h, 90 + angle_offset)
      end
    else
      bullet_manager.create_bullet(:straight, state.player.x + state.player.w / 2, state.player.y + state.player.h, 90)
    end
    audio_manager.player_shoot

    if state.player.powerups[:multi_shot]
      multi_shot_health = state.player.powerups[:multi_shot][:health]
      state.primary_weapon_cooldown = 24 - (multi_shot_health * 2)
    else
      state.primary_weapon_cooldown = 24
    end
  end

  def fire_secondary_weapon
    if state.player.powerups.include?(:seeking)
      bullet_manager.create_bullet(:seeking, state.player.x + state.player.w / 2, state.player.y + state.player.h, 90, nil, color: [0, 255, 0])
      audio_manager.player_shoot
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
    if state.score > state.wave * 1000 && state.wave < state.current_level.max_waves
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

  def update_level_timer
    state.current_level.time_remaining -= 1 if state.current_level.time_remaining > 0
  end

  def update_player_speed
    if state.player.powerups.include?(:speed)
      state.player.speed = 5 + (state.player.powerups[:speed][:level] * 2)
    else
      state.player.speed = 5
    end
  end

  def update_primary_weapon_cooldown
    state.primary_weapon_cooldown -= 1 if state.primary_weapon_cooldown > 0
  end

  def restart_game
    state.player = { x: 640, y: 40, w: 50, h: 50, speed: 5, health: state.current_level.initial_player_health, powerups: {} }
    bullet_manager.bullets = []
    enemy_bullet_manager.bullets = []
    state.enemies = []
    state.powerups = []
    state.wave = 1
    state.score = 0
    state.explosions = []
    state.game_over = false
    state.current_level.time_remaining = state.current_level.available_time
    state.primary_weapon_cooldown = 0
    audio_manager.play_background_music
  end
end
