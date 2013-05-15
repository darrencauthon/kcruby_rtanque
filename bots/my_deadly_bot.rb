class MyDeadlyBot < RTanque::Bot::Brain
  NAME = 'darren'
  include RTanque::Bot::BrainHelper

  def tick!
    @degree ||= 0
    @degree += 1
    @degree = 0 if @degree > 360

    command.fire MIN_FIRE_POWER
    command.radar_heading = RTanque::Heading.new_from_degrees @degree
    
    sensors.radar.each do |scanned_bot|
      command.heading = scanned_bot.heading
      command.speed = 3
      command.radar_heading = command.heading
      command.turret_heading = command.heading
    end
  end
end
