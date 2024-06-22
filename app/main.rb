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
    state.player_hit_cooldown ||= 0  # Add cooldown to prevent multiple hits at once
    state.explosions ||= []  # Add explosions array
    state.screen_width ||= 1280
    state.screen_height ||= 720
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
    # Move bullets
    state.bullets.each { |bullet| bullet.y += bullet.speed }
    state.bullets.reject! { |bullet| bullet.y > state.screen_height }

    # Move enemies
    state.enemies.each { |enemy| enemy.y -= enemy.speed }
    state.enemies.reject! { |enemy| enemy.y < 0 }

    # Spawn enemies
    state.enemy_spawn_timer -= 1
    if state.enemy_spawn_timer <= 0
      spawn_enemy
      state.enemy_spawn_timer = 60 - (state.wave * 2)
    end

    # Check collisions
    state.bullets.reject! do |bullet|
      state.enemies.reject! do |enemy|
        if bullet.intersect_rect?(enemy)
          state.score += 1
          # Create explosion
          state.explosions << { x: enemy.x + enemy.w / 2, y: enemy.y + enemy.h / 2, width: 10, height: 10, opacity: 255, age: 0 }
          true
        end
      end
    end

    # Update explosions
    state.explosions.each do |explosion|
      explosion.width += 15
      explosion.height += 15
      explosion.opacity -= 15
      explosion.y += 5
      explosion.age += 1.5
    end
    state.explosions.reject! { |explosion| explosion.age > 25 }

    # Check player-enemy collisions
    state.enemies.reject! do |enemy|
      # only subsctract from score if player is hit while not in cooldown
      puts state.player_hit_cooldown
      if state.player.intersect_rect?(enemy)
        if state.player_hit_cooldown <= 0
          state.score -= 2
          state.score = 0 if state.score < 0  # Prevent negative score
          state.player_hit_cooldown = 60  # Set cooldown to 1 second (60 frames)
        end
        # Create explosion for the enemy
        state.explosions << { x: enemy.x + enemy.w / 2, y: enemy.y + enemy.h / 2, width: 10, height: 10, opacity: 255, age: 0 }
        true  # Remove the enemy
      end
    end
    state.player_hit_cooldown -= 1 if state.player_hit_cooldown > 0

    # Increase difficulty
    if state.score > state.wave * 10
      state.wave += 1
    end
  end

  def render
    # Clear screen
    outputs.background_color = [0, 0, 0]

    # Render player
    outputs.sprites << [state.player.x, state.player.y, state.player.w, state.player.h, 'sprites/triangle/equilateral/orange.png']

    # Render bullets
    outputs.solids << state.bullets.map { |b| [b.x, b.y, b.w, b.h, 255, 255, 0] }

    # Render enemies
    outputs.sprites << state.enemies.map { |e| [e.x, e.y, e.w, e.h, 'sprites/circle/red.png', -90] }

    # Render explosions
    outputs.sprites << state.explosions.map do |e|
      [e.x - e.width / 2, e.y - e.height / 2, e.width, e.height, 'sprites/misc/explosion-3.png', 0, e.opacity, 255, 128, 0]
    end

    # Render UI
    outputs.labels << [1220, 710, "Score: #{state.score}", 1, 1, 255, 255, 255]  # Adjusted position for upper right corner
    outputs.labels << [1220, 680, "Wave: #{state.wave}", 1, 1, 255, 255, 255]
  end

  def spawn_enemy
    spawn_width = [state.screen_width / 4 * (state.wave / 5.0), state.screen_width].min
    spawn_x = (state.screen_width - spawn_width) / 2 + rand(spawn_width)
    state.enemies << { x: spawn_x, y: state.screen_height, w: 40, h: 40, speed: 2 + (state.wave * 0.5) }
  end
end

$game = Game.new

def tick args
  $game.args = args
  $game.tick
end
