class Darren < RTanque::Bot::Brain
  NAME = 'Darren'
  include RTanque::Bot::BrainHelper

  class Strategy

    MIN_FIRE_POWER = 1
    MAX_FIRE_POWER = 3
    MAX_BOT_SPEED  = 100

    def initialize bot
      @bot = bot
    end

    def self.inherited c
      @types ||= []
      @types << c
    end

    def self.setup(bot)
      return if @strategies
      @strategies = @types.map { |t| t.new bot }
    end

    def apply
    end

    def do_not_apply
    end

    def self.execute bot
      setup(bot) unless @strategies
      @strategies.select { |x| x.is_applicable? }.each do |s| 
        s.setup_default_values
        if s.is_applicable?
          s.apply
        else
          s.do_not_apply
        end
      end
    end

    def command
      @bot.command
    end

    def sensors
      @bot.sensors
    end

    def bots
      sensors.radar.sort_by { |x| x.distance }
    end

    def setup_default_values
      @direction  ||= :forward
      @hit_a_wall ||= false
      @start_time ||= Time.now
    end
  end

  def tick!
    Darren::Strategy.execute self
  end
end

# logic starts here

class ICantSeeAnybody < Darren::Strategy
  def is_applicable?
    bots.count == 0
  end

  def apply
    command.fire_power = MIN_FIRE_POWER
    spin_the_radar_in_a_circle
    command.speed = 1
  end

  def spin_the_radar_in_a_circle
    @degree ||= 0
    @degree += 3
    @degree = 0 if @degree > 360
    command.radar_heading  = RTanque::Heading.new_from_degrees @degree
    command.turret_heading = command.radar_heading
  end
end

class ISeeSomethingToShoot < Darren::Strategy

  def is_applicable?
    bots.count > 0
  end

  def apply
    bot = bots.first

    if @hit_a_wall == false && sensors.position.on_wall?
      @direction = (@direction != :forward) ? :forward : :backward
      @hit_a_wall = true
    end
    @hit_a_wall = false unless sensors.position.on_wall?

    speed = MAX_BOT_SPEED
    command.speed = @direction == :forward ? speed : -1 * speed

    command.heading        = bot.heading + 115
    command.radar_heading  = bot.heading
    command.turret_heading = bot.heading

    fire_power = MIN_FIRE_POWER
    if headings_are_the_same sensors.turret_heading, bot.heading
      fire_power = MAX_FIRE_POWER 
    end
    command.fire fire_power
  end

  def headings_are_the_same one, two
    one = (one.to_degrees * 5).to_i
    two = (two.to_degrees * 5).to_i
    one == two
  end

end
