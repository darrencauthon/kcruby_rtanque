class MyDeadlyBot < RTanque::Bot::Brain
  NAME = 'darren'
  include RTanque::Bot::BrainHelper

  def tick!
    @direction  ||= :forward
    @hit_a_wall ||= false
    @start_time ||= Time.now

    spin_the_radar_in_a_circle

    fire_power = MIN_FIRE_POWER
    range = MAX_FIRE_POWER - MIN_FIRE_POWER
    command.fire MIN_FIRE_POWER + rand(range)
    
    bot = bots_by_distance.first
    return unless bot

    if @hit_a_wall == false && sensors.position.on_wall?
      @direction = (@direction != :forward) ? :forward : :backward
      @hit_a_wall = true
    end
    @hit_a_wall = false unless sensors.position.on_wall?

    command.speed = @direction == :forward ? MAX_BOT_SPEED : -MAX_BOT_SPEED

    command.heading        = bot.heading + 90
    command.radar_heading  = bot.heading
    command.turret_heading = bot.heading
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
