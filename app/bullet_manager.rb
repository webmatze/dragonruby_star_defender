class BulletManager
  attr_accessor :bullets

  def initialize(game)
    @game = game
    @bullets = []
  end

  def create_bullet(type, x, y, angle, target = nil)
    bullet = case type
             when :straight
               StraightBullet.new(x, y, 5, 10, 10, angle)
             when :angled
               AngledBullet.new(x, y, 5, 10, 10, angle)
             when :seeking
               speed = 5 + (@game.state.player.powerups[:seeking][:level] * 3)
               SeekingBullet.new(x, y, speed, 10, 5, angle, target)
             end
    @bullets << bullet
  end

  def update
    @bullets.each(&:update)
    @bullets.reject! { |bullet| bullet.off_screen?(@game.state.screen_width, @game.state.screen_height) }
  end
end
