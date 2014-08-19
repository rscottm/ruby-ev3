require "ev3/motor"
require "ev3/button"

module EV3
  class Brick
    attr_reader :connection, :layer

    include EV3::Validations::Type

    # Create a new brick connection
    #
    # @param [instance subclassing Connections::Base] connection to the brick
    def initialize(connection)
      @connection = connection
      @layer = DaisyChainLayer::EV3
    end

    # Connect to the EV3
    def connect
      self.connection.connect
    end

    # Close the connection to the EV3
    def disconnect
      self.connection.disconnect
    end

    # Play a short beep on the EV3
    def beep
      self.execute(Commands::SoundTone.new)
    end

    # Play a tone on the EV3 using the specified options
    def play_tone(volume, frequency, duration)
      command = Commands::SoundTone.new(volume, frequency, duration)
      self.execute(command)
    end

    Motor::constants.each do |motor|
      motor_name = "motor_#{motor.downcase}"
      variable_name = "@#{motor_name}"
      define_method(motor_name) do
        if instance_variable_defined?(variable_name)
          instance_variable_get(variable_name)
        else
          instance_variable_set(variable_name, Motor.new(Motor::const_get(motor), self))
        end
      end
    end

    # Fetches the motor attached to the motor port
    # @param [sym in [:a, :b, :c, :d]] motor_port
    # @example get motor attached to port a
    #   motor_a = brick.motor(:a)
    def motor(motor_port)
      send("motor_#{motor_port.to_s.downcase}")
    end
    
    Button::constants.each do |button|
      button_name = "button_#{button.downcase}"
      variable_name = "@#{button_name}"
      define_method(button_name) do
        if instance_variable_defined?(variable_name)
          instance_variable_get(variable_name)
        else
          instance_variable_set(variable_name, Button.new(Button::const_get(button), self))
        end
      end
    end    

    # Fetches the button
    # @param [sym in [:left, :right, :up, :down, :back, :enter]]
    # @example get motor attached to port a
    #   button_left = brick.button(:left)
    def button(button_name)
      send("button_#{button_name.to_s.downcase}")
    end
    
    # Execute the command
    #
    # @param [instance subclassing Commands::Base] command to execute
    def execute(command)
      validate_type!(command, 'command', EV3::Commands::Base)
      self.connection.write(command)
    end
  end
end