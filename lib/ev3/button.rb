require 'ev3/actions/button'

module EV3
  class Button
    include EV3::Validations::Constant
    include EV3::Validations::Type
    
    include EV3::Actions::Button
    
    attr_writer :pressed

		UP    = 1
		ENTER = 2
		DOWN  = 3
		RIGHT = 4
		LEFT  = 5
		BACK  = 6
    
    def initialize(button, brick)
      validate_constant!(button, 'button', self.class)
      validate_type!(brick, 'brick', EV3::Brick)

      @button = button
      @brick = brick
    end
    
    def pressed?
      brick.execute(_pressed?)
      @pressed
    end
    
    private

    attr_reader :brick, :button

    # Helper for accessing the brick's layer (for daisy chaining)
    def layer
      brick.layer
    end
  end
end
