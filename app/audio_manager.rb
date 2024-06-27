class AudioManager
  def initialize(args)
    @args = args
    @background_music_playing = false
    @volume = 1.0
    @previous_volume = 1.0
  end

  def play_sound(key, sound_name)
    @args.audio[key] = { input: "sounds/#{sound_name}.mp3", gain: @volume }
  end

  def play_background_music
    unless @background_music_playing
      @args.audio[:bg_music] = { input: "sounds/Let Me See Ya Bounce.ogg", looping: true, gain: @volume }
      @background_music_playing = true
    end
  end

  def stop_background_music
    @args.audio[:bg_music] = false
    @background_music_playing = false
  end

  def increase_volume
    @volume = [@volume + 0.1, 1.0].min
    update_volume
  end

  def decrease_volume
    @volume = [@volume - 0.1, 0.0].max
    update_volume
  end

  def mute
    @previous_volume = @volume
    @volume = 0.0
    update_volume
  end

  def unmute
    @volume = @previous_volume
    update_volume
  end

  def muted?
    @volume == 0.0
  end

  def update_volume
    @args.audio.each do |key, sound|
      sound[:gain] = @volume if sound.is_a?(Hash)
    end
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
