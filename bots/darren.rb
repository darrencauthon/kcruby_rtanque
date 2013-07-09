class Darren < RTanque::Bot::Brain
  NAME = 'Darren'
  include RTanque::Bot::BrainHelper

  attr_accessor :strategies

  def before_turn
    strategies.each { |s| s.before_turn }
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

    def self.run_pre_turn_hooks_for bot
      bot.before_turn
    end

    def before_turn
      @bots = nil
    end

    def is_applicable?
      true
    end

    def apply
    end

    def do_not_apply
    end

    def self.execute bot
      load_strategies_for bot
      run_pre_turn_hooks_for bot
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

    def arena
      @bot.arena
    end

    def sensors
      @bot.sensors
    end

    def bots
      @bots ||= sensors.radar.sort_by { |x| x.distance }.map do |bot|
                  create_my_own_information_laden_copy_of bot
                end
    end

    def create_my_own_information_laden_copy_of bot
      bot                  = create_clone_with_extra_attributes_of bot
      bot.previous_points  = @other_bot_points[bot.name].map { |k, v| v }
      bot.x                = bot.previous_points.last[:x]
      bot.y                = bot.previous_points.last[:y]
      bot.speed            = get_speed_of bot
      bot.next_points      = calculate_next_points_for bot
      bot.firing_solutions = calculate_firing_solutions_for bot
      bot
    end

    def calculate_firing_solutions_for bot
      shell_speed_factor = RTanque::Configuration.shell.speed_factor
      firing_solutions = []
      bot.next_points.each_with_index.map do |point, tick|
        fire_power = 3
        expected_tick = bot.distance / (shell_speed_factor * fire_power)
        expected_tick = expected_tick.round
        if tick == expected_tick
          heading = heading_to point
          firing_solutions << { match: 0, fire_power: 3, point: point, heading: heading }
        end
      end
      firing_solutions
    end

    def calculate_next_points_for bot
      this_point = bot.previous_points[-1]
      last_point = bot.previous_points[-2]
      return [] unless this_point and last_point
      bot_heading = heading_to this_point, last_point
      (1..75).to_a.map do |tick|
        guess_where_this_bot_will_be_in_so_many_ticks bot, bot_heading, tick
      end
    end

    def guess_where_this_bot_will_be_in_so_many_ticks bot, bot_heading, tick
      x = (bot.x + (Math.sin(bot_heading) * bot.speed * tick)).round(10)
      y = (bot.y + (Math.cos(bot_heading) * bot.speed * tick)).round(10)
      x = 0 if x <= 0
      x = arena.width if x >= arena.width
      y = 0 if y <= 0
      y = arena.height if y >= arena.height
      { x: x, y: y }
    end

    def get_speed_of bot
      this_point = bot.previous_points[-1]
      last_point = bot.previous_points[-2]
      diff_in_x  = last_point[:x] - this_point[:x]
      diff_in_y  = last_point[:y] - this_point[:y]
      speed      = Math.sqrt((diff_in_x * diff_in_x) + (diff_in_y * diff_in_y)).round(10)
    rescue
      0
    end

    def heading_to to, from = sensors.position
      to   = hash_to_point to if to.instance_of? Hash
      from = hash_to_point to if from.instance_of? Hash
      RTanque::Heading.new_between_points from, to
    end

    def hash_to_point point
      RTanque::Point.new point[:x], point[:y]
    end

    def create_clone_with_extra_attributes_of bot
      bot = bot.clone
      bot.instance_eval do
        def x
          @x
        end

        def x= value
          @x = value
        end

        def y
          @y
        end

        def y= value
          @y = value
        end

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

        def next_points
          @next_points
        end

        def next_points= points
          @next_points = points
        end

        def firing_solutions
          @firing_solutions
        end

        def firing_solutions= values
          @firing_solutions = values
        end
      end
      bot
    end

    def setup_default_values
      @direction  ||= :forward
      @start_time ||= Time.now
      determine_if_a_wall_was_just_hit
      load_information_necessary_for_important_calculations
    end

    def load_information_necessary_for_important_calculations
      record_where_i_have_been
      record_where_the_other_bots_have_been
    end

    def record_where_i_have_been
      @my_points ||= {}
      @my_points[sensors.ticks] = sensors.position
    end

    def record_where_the_other_bots_have_been
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
  def apply
    command.fire_power = MIN_FIRE_POWER
  end
end

class Darren::SuddenReversalIfWallIsHit < Darren::Strategy
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

class Darren::UseFiringSolutions < Darren::Strategy
  def apply
    bot = bots.first
    firing_solution = bot.firing_solutions.first
    point = firing_solution[:point]
    command.turret_heading = heading_to point
    command.fire firing_solution[:fire_power]
  end

  def is_applicable?
    b = bots
    b.count > 0 && b.first.firing_solutions.count > 0
  end
end

class Darren::ShootBotsThatAreNotMoving < Darren::Strategy
  def apply
    command.turret_heading = bots_that_are_not_moving.first.heading
    command.fire 3
  end

  def is_applicable?
    bots_that_are_not_moving.count > 0
  end

  def bots_that_are_not_moving
    bots.select { |x| x.speed == 0 }
  end
end

class Darren::DriveInACircle < Darren::Strategy
  def apply
    if @point.nil?
      @point = sensors.position
    end
    command.heading = heading_to @point
  end
end
