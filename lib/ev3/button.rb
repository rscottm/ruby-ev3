require 'ev3/actions/button'

module EV3
  class Button
    include EV3::Validations::Constant
    include EV3::Validations::Type
    
    include EV3::Actions::Button
    
    attr_writer :pressed
    attr_reader :name

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
      @name = self.class.constants[button-1].downcase.to_sym
      @brick = brick
      @pressed = false
      @on_button_changed = nil
    end

    def self.on_button_changed
      @on_button_changed
    end

    def self.on_button_changed=(change_proc)
      @on_button_changed = change_proc
    end

    def on_button_changed
      @on_button_changed || self.class.on_button_changed
    end

    def on_button_changed=(change_proc)
      @on_button_changed = change_proc
    end
    
    def pressed?
      brick.execute(_pressed?)
    end
    
    def pressed=(value)
      (@pressed = value; on_button_changed.call(self, value)) if @pressed != value and on_button_changed
      @pressed = value
    end
    
    private

    attr_reader :brick, :button

    # Helper for accessing the brick's layer (for daisy chaining)
    def layer
      brick.layer
    end
  end
end
