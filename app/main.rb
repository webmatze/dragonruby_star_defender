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
    state.bullets.reject! { |bullet| bullet.y > 720 }

    # Move enemies
    state.enemies.each { |enemy| enemy.y -= enemy.speed }
    state.enemies.reject! { |enemy| enemy.y < 0 }

    # Spawn enemies
    state.enemy_spawn_timer -= 1
    if state.enemy_spawn_timer <= 0
      state.enemies << { x: rand(1280), y: 720, w: 40, h: 40, speed: 2 + (state.wave * 0.5) }
      state.enemy_spawn_timer = 60 - (state.wave * 2)
    end

    # Check collisions
    state.bullets.reject! do |bullet|
      state.enemies.reject! do |enemy|
        if bullet.intersect_rect?(enemy)
          state.score += 1
          true
        end
      end
    end

    # Check player-enemy collisions
    if state.player_hit_cooldown <= 0
      state.enemies.each do |enemy|
        if state.player.intersect_rect?(enemy)
          state.score -= 10
          state.score = 0 if state.score < 0  # Prevent negative score
          state.player_hit_cooldown = 60  # Set cooldown to 1 second (60 frames)
          break
        end
      end
    else
      state.player_hit_cooldown -= 1
    end

    # Increase difficulty
    if state.score > state.wave * 10
      state.wave += 1
    end
  end

  def render
    # Clear screen
    outputs.background_color = [0, 0, 0]

    # Render player
    outputs.solids << [state.player.x, state.player.y, state.player.w, state.player.h, 255, 255, 255]

    # Render bullets
    outputs.solids << state.bullets.map { |b| [b.x, b.y, b.w, b.h, 255, 255, 0] }

    # Render enemies
    outputs.solids << state.enemies.map { |e| [e.x, e.y, e.w, e.h, 255, 0, 0] }

    # Render UI
    outputs.labels << [1220, 710, "Score: #{state.score}", 1, 1, 255, 255, 255]  # Adjusted position for upper right corner
    outputs.labels << [10, 680, "Wave: #{state.wave}"]
  end
end

$game = Game.new

def tick args
  $game.args = args
  $game.tick
end
