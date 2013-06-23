class MyDeadlyBot < RTanque::Bot::Brain
  NAME = 'darren'
  include RTanque::Bot::BrainHelper

  def tick!
    @direction  ||= :forward
    @hit_a_wall ||= false
    @start_time ||= Time.now

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

    command.heading        = bot.heading + 90
    command.radar_heading  = bot.heading
    command.turret_heading = bot.heading

    fire_power = MIN_FIRE_POWER
    fire_power = MAX_FIRE_POWER if headings_are_the_same sensors.turret_heading, bot.heading
    command.fire fire_power
  end

  def headings_are_the_same one, two
    one = (one.to_degrees * 2).to_i
    two = (two.to_degrees * 2).to_i
    one == two
  end

  def bots_by_distance
    sensors.radar.sort { |x| x.distance }
  end

  def spin_the_radar_in_a_circle
    @degree ||= 0
    @degree += 5
    @degree = 0 if @degree > 360
    command.radar_heading = RTanque::Heading.new_from_degrees @degree
  end
end
