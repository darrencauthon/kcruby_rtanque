class MyDeadlyBot < RTanque::Bot::Brain
  NAME = 'darren'
  include RTanque::Bot::BrainHelper

  def tick!
    ## main logic goes here
    
    # use self.sensors to detect things
    # See http://rubydoc.info/github/awilliams/RTanque/master/RTanque/Bot/Sensors
    
    # use self.command to control tank
    # See http://rubydoc.info/github/awilliams/RTanque/master/RTanque/Bot/Command
    
    # self.arena contains the dimensions of the arena
    # See http://rubydoc.info/github/awilliams/RTanque/master/frames/RTanque/Arena
  end
end
