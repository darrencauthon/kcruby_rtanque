class MyDeadlyBot < RTanque::Bot::Brain
  NAME = 'darren'
  include RTanque::Bot::BrainHelper

  def tick!
    @degree ||= 0
    @degree += 1
    @degree = 0 if @degree > 360

    ## main logic goes here
    
    # use self.sensors to detect things
    # See http://rubydoc.info/github/awilliams/RTanque/master/RTanque/Bot/Sensors
    
    # use self.command to control tank
    # See http://rubydoc.info/github/awilliams/RTanque/master/RTanque/Bot/Command
    self.command.fire MIN_FIRE_POWER
    self.command.radar_heading = RTanque::Heading.new_from_degrees @degree
    #self.command.turret_heading = RTanque::Heading.new_from_degrees @degree
    
    sensors.radar.each do |scanned_bot|
      # scanned_bot: RTanque::Bot::Radar::Reflection
      # Reflection(:heading, :distance, :name)
      command.heading = scanned_bot.heading
      command.speed = 3
      self.command.radar_heading = command.heading
      self.command.turret_heading = command.heading
    end
    
    # self.arena contains the dimensions of the arena
    # See http://rubydoc.info/github/awilliams/RTanque/master/frames/RTanque/Arena
  end
end
