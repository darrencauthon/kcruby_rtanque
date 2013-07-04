class Darren < RTanque::Bot::Brain
  NAME = 'Darren'
  include RTanque::Bot::BrainHelper

  attr_accessor :strategies

  class Strategy

    MIN_FIRE_POWER = 1
    MAX_FIRE_POWER = 3
    MAX_BOT_SPEED  = 100

    attr_reader :hit_a_wall

    def initialize bot
      @bot = bot
      @echoes = {}
      @points = {}
    end

    def self.inherited c
      @types ||= []
      @types << c
    end

    def self.load_strategies_for bot
      return if bot.strategies
      bot.strategies = @types.map { |t| t.new bot }
    end

    def is_applicable?
    end

    def apply
    end

    def do_not_apply
    end

    def self.execute bot
      load_strategies_for bot
      bot.strategies.each do |s| 
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
puts '---'
#degr := arctand ((y2 - y1) / (x2 - x1))
first = @echoes.keys.first
last = @echoes.keys.last
if @echoes[first] && @echoes[last]
end
puts '---'
      current_bots = sensors.radar.sort_by { |x| x.distance }
      return current_bots if current_bots.count > 0
      []
    end

    def setup_default_values
      @direction  ||= :forward
      @start_time ||= Time.now
      determine_if_a_wall_was_just_hit
      supplement_the_radar_with_echos_of_bots_past
    end

    def supplement_the_radar_with_echos_of_bots_past
      @points ||= {}
      @points[sensors.ticks] = sensors.position

      @echoes ||= {}
      @echoes[sensors.ticks] = sensors.radar.to_a

      sensors.radar.each do |reflection|
        begin
          distance = reflection.distance
          radians = reflection.heading.to_f
          y = Math.cos(radians) * distance
          distance = reflection.distance
          radians = reflection.heading.to_f
          x = Math.sin(radians) * distance
          puts [y, x].inspect
          puts [x+ @points[sensors.ticks].x, y+ @points[sensors.ticks].y].inspect
        rescue
        end
      end

      keys = @echoes.keys.select { |k| k + 10 <= sensors.ticks }
      keys.each { |k| @echoes.delete k }
    end

    def determine_if_a_wall_was_just_hit
      @hit_a_wall == false
      if sensors.position.on_wall?
        @hit_a_wall = !@still_touching_a_wall
        @still_touching_a_wall = true
      else
        @hit_a_wall = false
        @still_touching_a_wall = false
      end
    end

    def headings_are_the_same one, two
      one = (one.to_degrees * 5).to_i
      two = (two.to_degrees * 5).to_i
      one == two
    end
  end

  def tick!
    Darren::Strategy.execute self
  end
end

# logic starts here

class Darren::AlwaysFireSomething < Darren::Strategy
  def is_applicable?
    true
  end

  def apply
    command.fire_power = MIN_FIRE_POWER
  end
end

class Darren::SuddenReversalIfWallIsHit < Darren::Strategy
  def is_applicable?
    true
  end

  def apply
    command.speed = speed
  end

  def speed
    if hit_a_wall
      @direction = (@direction != :forward) ? :forward : :backward 
    end
    @direction == :forward ? MAX_BOT_SPEED : -1 * MAX_BOT_SPEED
  end
end

class Darren::ICantSeeAnybody < Darren::Strategy
  def is_applicable?
    bots.count == 0
  end

  def apply
    spin_the_radar_in_a_circle
  end

  def spin_the_radar_in_a_circle
    @degree ||= 0
    @degree += 3
    @degree = 0 if @degree > 360
    command.radar_heading  = RTanque::Heading.new_from_degrees @degree
    command.turret_heading = command.radar_heading
  end
end

class Darren::ISeeSomethingToShoot < Darren::Strategy
  def apply
    bot = bots.first
    command.heading        = bot.heading + 115
    command.radar_heading  = bot.heading
    command.turret_heading = bot.heading
  end

  def is_applicable?
    bots.count > 0
  end
end
