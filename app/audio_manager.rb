class AudioManager
  def initialize(args)
    @args = args
    @background_music_playing = false
  end

  def play_sound(key, sound_name)
    @args.audio[key] = { input: "sounds/#{sound_name}.mp3" }
  end

  def play_background_music
    unless @background_music_playing
      @args.audio[:bg_music] = { input: "sounds/Let Me See Ya Bounce.ogg", looping: true }
      @background_music_playing = true
    end
  end

  def stop_background_music
    @args.audio[:bg_music] = false
    @background_music_playing = false
  end

  def player_shoot
    play_sound(:player_shoot, 'Simple Shot 1')
  end

  def bullet_hit
    play_sound(:bullet_hit, 'Simple Shot 2')
  end

  def explosion
    play_sound(:explosion, 'Explosion 1')
  end

  def player_hit
    play_sound(:player_hit, 'Explosion 2')
  end

  def shield_hit
    play_sound(:shield_hit, 'Turn Off')
  end

  def powerup_pickup
    play_sound(:powerup_pickup, 'What')
  end

  def health_pickup
    play_sound(:health_pickup, 'Triple Bleep')
  end

  def game_over
    play_sound(:game_over, 'Game Over Music 2')
  end
end
