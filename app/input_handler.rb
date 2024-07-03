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

    # Pause/Unpause
    if inputs.keyboard.key_down.p
      @game.audio_manager.play_background_music if state.paused
      state.paused = !state.paused
      @game.audio_manager.stop_background_music if state.paused
    end

    return if state.paused

    # Speed powerup
    if state.player.powerups.include?(:speed)
      state.player.speed = 5 + (state.player.powerups[:speed][:level] * 2)
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
      @game.fire_player_bullets
    end

    # Volume control
    if inputs.keyboard.key_down.plus || inputs.keyboard.key_down.equal_sign
      @game.audio_manager.increase_volume
    end
    if inputs.keyboard.key_down.minus || inputs.keyboard.key_down.underscore
      @game.audio_manager.decrease_volume
    end

    # Mute/unmute
    if inputs.keyboard.key_down.m
      if @game.audio_manager.muted?
        @game.audio_manager.unmute
      else
        @game.audio_manager.mute
      end
    end
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

    # Pause/Unpause
    if inputs.controller_one.key_down.start
      @game.audio_manager.play_background_music if state.paused
      state.paused = !state.paused
      @game.audio_manager.stop_background_music if state.paused
    end

    return if state.paused

    # Speed powerup
    if state.player.powerups.include?(:speed)
      state.player.speed = 5 + (state.player.powerups[:speed][:level] * 2)
    else
      state.player.speed = 5
    end

    # Player movement
    state.player.x -= state.player.speed if inputs.controller_one.left
    state.player.x += state.player.speed if inputs.controller_one.right
    state.player.y -= state.player.speed if inputs.controller_one.down
    state.player.y += state.player.speed if inputs.controller_one.up

    # Keep player within screen bounds
    state.player.x = state.player.x.clamp(0, state.screen_width - state.player.w)
    state.player.y = state.player.y.clamp(0, state.screen_height - state.player.h)

    # Shooting
    if inputs.controller_one.key_down.a
      @game.fire_player_bullets
    end

    # Volume control
    if inputs.controller_one.key_down.r1
      @game.audio_manager.increase_volume
    end
    if inputs.controller_one.key_down.l1
      @game.audio_manager.decrease_volume
    end

    # Mute/unmute
    if inputs.controller_one.key_down.select
      if @game.audio_manager.muted?
        @game.audio_manager.unmute
      else
        @game.audio_manager.mute
      end
    end
  end
end
