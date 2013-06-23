class MyDeadlyBot < RTanque::Bot::Brain
  NAME = 'darren'
  include RTanque::Bot::BrainHelper

  def tick!
    spin_the_radar_in_a_circle

    fire_power = MIN_FIRE_POWER
    range = MAX_FIRE_POWER - MIN_FIRE_POWER
    command.fire MIN_FIRE_POWER + rand(range)
    
    bot = bots_by_distance.first
    return unless bot

    if bot.distance < 300
      command.speed = 0
    else
      command.speed = MAX_BOT_SPEED
    end

    command.heading        = bot.heading
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
