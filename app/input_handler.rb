class InputHandler
  def initialize(game)
    @game = game
  end

  def handle_input
    handle_keyboard_input
    handle_mouse_input
    handle_controller_input
  end

  private

  def state
    @game.state
  end

  def inputs
    @game.args.inputs
  end

  def handle_keyboard_input
    if state.game_over
      @game.restart_game if inputs.keyboard.key_down.r
      return
    end

    handle_pause_input(inputs.keyboard.key_down.p)
    return if state.paused

    handle_player_movement(inputs.keyboard)
    handle_primary_weapon_shooting(inputs.keyboard.key_held.space)
    handle_secondary_weapon_shooting(inputs.keyboard.key_down.ctrl)
    handle_increase_volume(inputs.keyboard.key_down.plus)
    handle_decrease_volume(inputs.keyboard.key_down.minus)
    handle_mute_toggle(inputs.keyboard.key_down.m)
  end

  def handle_mouse_input
    if inputs.mouse.click
      handle_mouse_click
    end
  end

  def handle_mouse_click
    # Add mouse click handling logic here
    # For example, clicking buttons in the UI
  end

  def handle_controller_input
    return unless inputs.controller_one

    if state.game_over
      @game.restart_game if inputs.controller_one.key_down.start
      return
    end

    handle_pause_input(inputs.controller_one.key_down.start)
    return if state.paused

    handle_player_movement(inputs.controller_one)
    handle_primary_weapon_shooting(inputs.controller_one.key_held.a)
    handle_secondary_weapon_shooting(inputs.controller_one.key_down.b)
    handle_increase_volume(inputs.controller_one.key_down.r1)
    handle_decrease_volume(inputs.controller_one.key_down.l1)
    handle_mute_toggle(inputs.controller_one.key_down.select)
  end

  def handle_pause_input(pause_key)
    if pause_key
      @game.audio_manager.play_background_music if state.paused
      state.paused = !state.paused
      @game.audio_manager.stop_background_music if state.paused
    end
  end

  def handle_player_movement(input_source)
    state.player.x -= state.player.speed if input_source.left
    state.player.x += state.player.speed if input_source.right
    state.player.y -= state.player.speed if input_source.down
    state.player.y += state.player.speed if input_source.up

    # Keep player within screen bounds
    state.player.x = state.player.x.clamp(0, state.screen_width - state.player.w)
    state.player.y = state.player.y.clamp(0, state.screen_height - state.player.h)
  end

  def handle_primary_weapon_shooting(shoot_key)
    @game.fire_primary_weapon if shoot_key
  end

  def handle_secondary_weapon_shooting(shoot_key)
    @game.fire_secondary_weapon if shoot_key
  end

  def handle_increase_volume(increase_key)
    @game.audio_manager.increase_volume if increase_key
  end

  def handle_decrease_volume(decrease_key)
    @game.audio_manager.decrease_volume if decrease_key
  end

  def handle_mute_toggle(mute_key)
    if mute_key
      if @game.audio_manager.muted?
        @game.audio_manager.unmute
      else
        @game.audio_manager.mute
      end
    end
  end
end
