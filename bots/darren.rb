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

    def self.execute bot
      setup(bot) unless @strategies
      @strategies.each { |x| x.turn }
    end

    def command
      @bot.command
    end

    def sensors
      @bot.sensors
    end
  end

  class DefaultStrategy < Strategy
    def turn
      set_default_values

      command.fire_power = MIN_FIRE_POWER

      spin_the_radar_in_a_circle

      bot = bots_by_distance.first
      return unless bot

      if @hit_a_wall == false && sensors.position.on_wall?
        @direction = (@direction != :forward) ? :forward : :backward
        @hit_a_wall = true
      end
      @hit_a_wall = false unless sensors.position.on_wall?

      speed = MAX_BOT_SPEED
      command.speed = @direction == :forward ? speed : -1 * speed

      command.heading        = bot.heading + 95
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

    def bots_by_distance
      sensors.radar.sort_by { |x| x.distance }
    end

    def spin_the_radar_in_a_circle
      @degree ||= 0
      @degree += 5
      @degree = 0 if @degree > 360
      command.radar_heading = RTanque::Heading.new_from_degrees @degree
    end

    def set_default_values
      @direction  ||= :forward
      @hit_a_wall ||= false
      @start_time ||= Time.now
    end
  end

  def tick!
    Darren::Strategy.execute self
  end
end
