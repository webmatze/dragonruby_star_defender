class RenderManager
  def initialize(game)
    @game = game
  end

  def render
    # Set background to black
    outputs.background_color = [ 0, 0, 0 ]
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
    outputs.labels << { x: state.screen_width / 2, y: state.screen_height / 2 + 50, text: "You lose!", size_enum: 5, alignment_enum: 1, r: 255, g: 0, b: 0 }
    outputs.labels << { x: state.screen_width / 2, y: state.screen_height / 2, text: "Final Score: #{state.score}", size_enum: 3, alignment_enum: 1, r: 255, g: 255, b: 0 }
    outputs.labels << { x: state.screen_width / 2, y: state.screen_height / 2 - 50, text: "Press 'R' to restart", size_enum: 2, alignment_enum: 1, r: 255, g: 255, b: 255 }
  end

  def render_starfield
    outputs.sprites << state.starfield.flatten.map do |star|
      { x: star.x, y: star.y, w: star[:size], h: star[:size], path: 'sprites/circle/white.png', angle: 0, a: star.alpha }
    end
  end

  def render_player
    index = Numeric.frame_index count: 2, hold_for: 8, repeat_index: 0, repeat: true
    outputs.sprites << {
      x: state.player.x,
      y: state.player.y,
      w: state.player.w,
      h: state.player.h,
      path: "sprites/ship/red/sprite_#{index}.png"
    }

    if state.player.powerups.include?(:shield)
      shield_size = [state.player.w, state.player.h].max * 1.8
      shield_x = state.player.x + state.player.w / 2 - shield_size / 2
      shield_y = state.player.y + state.player.h / 2 - shield_size / 2
      outputs.sprites << { x: shield_x, y: shield_y, w: shield_size, h: shield_size, path: 'sprites/circle/yellow.png', angle: 0, a: 64 }
    end
  end

  def render_bullets
    outputs.solids << @game.bullet_manager.bullets.map(&:render)
  end

  def render_enemy_bullets
    outputs.solids << @game.enemy_bullet_manager.bullets.map(&:render)
  end

  def render_enemies
    outputs.sprites << state.enemies.map(&:to_h)
  end

  def render_explosions
    outputs.sprites << state.explosions.map do |e|
      frame = (e.age / 4).to_i % 7  # Cycle through 7 frames (0-6)
      {
        x: e.x - e.width / 2,
        y: e.y - e.height / 2,
        w: e.width,
        h: e.height,
        path: "sprites/misc/explosion-#{frame}.png",
        angle: 0,
        a: e.opacity,
        r: 255,
        g: 128,
        b: 0
      }
    end
  end

  def render_powerups
    outputs.sprites << state.powerups.map do |powerup|
      { x: powerup.x, y: powerup.y, w: powerup.w, h: powerup.h, path: powerup.sprite, angle: 0, a: 255 }
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
    outputs.primitives << { x: 0, y: 0, w: state.screen_width, h: state.screen_height, r: 0, g: 0, b: 0, a: 128 }.to_solid
    outputs.labels << { x: state.screen_width / 2, y: state.screen_height / 2 + 50, text: "PAUSED", size_enum: 5, alignment_enum: 1, r: 255, g: 255, b: 255 }
    outputs.labels << { x: state.screen_width / 2, y: state.screen_height / 2 - 50, text: "Press 'P' to resume", size_enum: 2, alignment_enum: 1, r: 255, g: 255, b: 255 }
  end

  def render_debug_information
    outputs.debug << "current tick: #{Kernel.tick_count}"
    outputs.debug << "FPS: #{@game.args.gtk.current_framerate}"
    outputs.debug << "Player position: #{state.player.x}, #{state.player.y}"
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
    outputs.solids << state.current_level.initial_player_health.times.map do |i|
      color = i < state.player.health ? [255, 0, 0] : [100, 100, 100]
      { x: state.screen_width - 20 - (i * 30), y: 700, w: 20, h: 20, r: color[0], g: color[1], b: color[2] }
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
