class Darren < RTanque::Bot::Brain
  NAME = 'Darren'
  include RTanque::Bot::BrainHelper

  attr_accessor :strategies

  def before_turn
    strategies.each { |s| s.before_turn }
  end

  class Strategy

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

    class << self
      attr_accessor :min_speed, :max_speed, 
                    :min_power, :max_power
    end

    def before_turn
      @bots = nil
    end

    def is_applicable?
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
        fire_power = Darren::Strategy.max_power
        expected_tick = bot.distance / (shell_speed_factor * fire_power)
        expected_tick = expected_tick.round
        if tick == expected_tick
          heading = RTanque::Heading.new_between_points(sensors.position, RTanque::Point.new(point[:x], point[:y]))
          firing_solutions << { match: 0, fire_power: Darren::Strategy.max_power, point: point, heading: heading }
        end
      end
      firing_solutions
    end

    def calculate_next_points_for bot
      this_point = bot.previous_points[-1]
      last_point = bot.previous_points[-2]
      return [] unless this_point and last_point
      bot_heading = RTanque::Heading.new_between_points(RTanque::Point.new(last_point[:x], last_point[:y]),
                                                        RTanque::Point.new(this_point[:x], this_point[:y]))
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
    strategy = Darren::Strategy
    strategy.min_power = 1
    strategy.max_power = 3
    strategy.min_speed = 1
    strategy.max_speed = 3
    Darren::Strategy.execute self
  end
end

# logic starts here

class Darren::AlwaysFireSomething < Darren::Strategy
  def is_applicable?
    true
  end

  def apply
    command.fire_power = Darren::Strategy.min_power
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
    @direction == :forward ? Darren::Strategy.max_speed : -1 * Darren::Strategy.max_speed
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
    command.turret_heading = RTanque::Heading.new_between_points(sensors.position, RTanque::Point.new(point[:x], point[:y]))
    command.fire firing_solution[:fire_power]
    command.radar_heading = bot.heading
  end

  def is_applicable?
    b = bots
    b.count > 0 && b.first.firing_solutions.count > 0
  end
end

class Darren::ShootBotsThatAreNotMoving < Darren::Strategy
  def apply
    command.turret_heading = bots_that_are_not_moving.first.heading
    command.fire Darren::Strategy.max_power
  end

  def is_applicable?
    bots_that_are_not_moving.count > 0
  end

  def bots_that_are_not_moving
    bots.select { |x| x.speed == 0 }
  end
end

class Darren::MoveTowardsTheArenaCenterIfIGetCloseToTheWall < Darren::Strategy
  def is_applicable?
    is_near_an_edge?
  end

  def apply
    command.heading = RTanque::Heading.new_between_points sensors.position, middle_of_the_field
    command.speed   = Darren::Strategy.max_speed
  end

  def arena
    sensors.position.arena
  end

  def middle_of_the_field
    RTanque::Point.new(sensors.position.arena.width  / 2, 
                       sensors.position.arena.height / 2)
  end

  def x_limits
    [ 
      { from: 0,                 to: 150         },
      { from: arena.width - 150, to: arena.width }
    ]
  end

  def y_limits
    [ 
      { from: 0,                  to: 150          },
      { from: arena.height - 150, to: arena.height }
    ]
  end

  def is_near_an_edge?
    count  = x_limits.select do |l|
               sensors.position.x >= l[:from] && sensors.position.x <= l[:to]
             end.count
    count += y_limits.select do |l|
               sensors.position.y >= l[:from] && sensors.position.y <= l[:to]
            end.count
    count > 0
  end
end

class Darren::RunToTheMiddleIfNotBotsCanBeSeen < Darren::Strategy
  def is_applicable?
    bots.count == 0
  end

  def apply
    command.heading = RTanque::Heading.new_between_points sensors.position, middle_of_the_field
    command.speed   = Darren::Strategy.max_speed
  end

  def middle_of_the_field
    RTanque::Point.new(sensors.position.arena.width  / 2, 
                       sensors.position.arena.height / 2)
  end
end
