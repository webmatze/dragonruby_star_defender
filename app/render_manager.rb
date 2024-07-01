class RenderManager
  def initialize(game)
    @game = game
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
    else
      render_explosions
      render_game_over
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
    outputs.sprites << [state.player.x, state.player.y, state.player.w, state.player.h, 'sprites/ship/space ship-2.png']

    if state.player.powerups.include?(:shield)
      shield_size = [state.player.w, state.player.h].max * 1.8
      shield_x = state.player.x + state.player.w / 2 - shield_size / 2
      shield_y = state.player.y + state.player.h / 2 - shield_size / 2
      outputs.sprites << [shield_x, shield_y, shield_size, shield_size, 'sprites/circle/yellow.png', 0, 64]
    end
  end

  def render_bullets
    @game.bullet_manager.bullets.each do |bullet|
      outputs.solids << [bullet.x, bullet.y, bullet.w, bullet.h, 255, 255, 0]
    end
  end

  def render_enemy_bullets
    @game.enemy_bullet_manager.bullets.each do |bullet|
      outputs.solids << [bullet.x, bullet.y, bullet.w, bullet.h, 255, 0, 0]
    end
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

    render_powerup_inventory
    render_player_health
    render_pause_menu if state.paused
    render_debug_information
  end

  def render_pause_menu
    outputs.primitives << [0, 0, state.screen_width, state.screen_height, 0, 0, 0, 128].solid
    outputs.labels << [state.screen_width / 2, state.screen_height / 2 + 50, "PAUSED", 5, 1, 255, 255, 255]
    outputs.labels << [state.screen_width / 2, state.screen_height / 2 - 50, "Press 'P' to resume", 2, 1, 255, 255, 255]
  end

  def render_debug_information
    outputs.debug << "current tick: #{Kernel.tick_count}"
    outputs.debug << "FPS: #{@game.args.gtk.current_framerate}"
  end

  def render_powerup_inventory
    state.player.powerups.each_with_index do |(type, powerup), index|
      powerup_sprite = case type
                       when :multi_shot then 'sprites/powerups/powerups-2.png'
                       when :speed then 'sprites/powerups/powerups-3.png'
                       when :shield then 'sprites/powerups/powerups-1.png'
                       when :seeking then 'sprites/hexagon/indigo.png'
                       end

      outputs.sprites << { x: 10, y: 540 - (index * 80), w: 64, h: 64, path: powerup_sprite }
      outputs.borders << { x: 8, y: 538 - (index * 80), w: 68, h: 68, r: 255, g: 255, b: 255 }

      # Render level and health
      outputs.labels << { x: 80, y: 580 - (index * 80), text: "Lvl: #{powerup[:level]}/#{powerup[:max_level]}", size_enum: 0, r: 255, g: 255, b: 255 }
      outputs.labels << { x: 80, y: 560 - (index * 80), text: "HP: #{powerup[:health]}", size_enum: 0, r: 255, g: 255, b: 255 }
    end
  end

  def render_player_health
    state.current_level.initial_player_health.times do |i|
      color = i < state.player.health ? [255, 0, 0] : [100, 100, 100]
      outputs.solids << [state.screen_width - 20 - (i * 30), 700, 20, 20, *color]
    end
  end

  private

  def outputs
    @game.outputs
  end

  def state
    @game.state
  end
end
