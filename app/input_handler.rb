class InputHandler
  def initialize(game)
    @game = game
  end

  def handle_input
    handle_keyboard_input
    handle_mouse_input
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
end
