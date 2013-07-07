class Darren < RTanque::Bot::Brain
  NAME = 'Darren'
  include RTanque::Bot::BrainHelper

  attr_accessor :strategies

  class Point
    attr_accessor :name, :x, :y
  end

  class Strategy

    MIN_FIRE_POWER = 1
    MAX_FIRE_POWER = 3
    MAX_BOT_SPEED  = 100

    attr_reader :hit_a_wall

    def initialize bot
      @bot = bot
      @other_bot_points = {}
      @my_points = {}
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
      sensors.radar.sort_by { |x| x.distance }.map do |x| 
        bot = create_internal_copy_of x
        bot.previous_points = @other_bot_points[bot.name].map { |k, v| v }
        bot.speed = get_speed_of bot
        puts bot.speed
        bot
      end
    end

    def get_speed_of bot
      last_point =         bot.previous_points[-1]
      next_to_last_point = bot.previous_points[-2]
      diff_in_x = (next_to_last_point[:x] - last_point[:x])
      diff_in_y = (next_to_last_point[:y] - last_point[:y])
      speed = Math.sqrt((diff_in_x * diff_in_x) + (diff_in_y * diff_in_y)).round(10)
    rescue
      0
    end

    def create_internal_copy_of bot
      bot = bot.clone
      bot.instance_eval do
        def speed
          @speed
        end

        def speed= value
          @speed = value
        end

        def previous_points
          @previous_points
        end

        def previous_points= points
          @previous_points = points
        end
      end
      bot
    end

    def setup_default_values
      @direction  ||= :forward
      @start_time ||= Time.now
      determine_if_a_wall_was_just_hit
      supplement_the_radar_with_echos_of_bots_past
    end

    def supplement_the_radar_with_echos_of_bots_past
      load_up_my_points
      load_up_the_other_bot_points
    end

    def load_up_my_points
      @my_points ||= {}
      @my_points[sensors.ticks] = sensors.position
    end

    def load_up_the_other_bot_points
      @other_bot_points ||= {}
      sensors.radar.each do |reflection|
        begin
          distance = reflection.distance
          radians = reflection.heading.to_f

          y = Math.cos(radians) * distance
          x = Math.sin(radians) * distance

          x = (x + sensors.position.x).round(10)
          y = (y + sensors.position.y).round(10)

          @other_bot_points[reflection.name] ||= {}
          @other_bot_points[reflection.name][sensors.ticks] = {x: x, y: y}

          keys = @other_bot_points[reflection.name].keys.select { |k| k + 10 <= sensors.ticks }
          keys.each { |k| @other_bot_points[reflection.name].delete k }
        end
      end
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
