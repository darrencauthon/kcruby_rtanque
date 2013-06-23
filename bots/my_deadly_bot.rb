class MyDeadlyBot < RTanque::Bot::Brain
  NAME = 'darren'
  include RTanque::Bot::BrainHelper

  def tick!
    spin_the_radar_in_a_circle

    command.fire MIN_FIRE_POWER
    
    sensors.radar.each do |scanned_bot|
      puts scanned_bot.inspect
      command.heading = scanned_bot.heading
      command.speed = 3
      command.radar_heading = command.heading
      command.turret_heading = command.heading
    end
  end

  def spin_the_radar_in_a_circle
    @degree ||= 0
    @degree += 10
    @degree = 0 if @degree > 360
    command.radar_heading = RTanque::Heading.new_from_degrees @degree
  end
end
