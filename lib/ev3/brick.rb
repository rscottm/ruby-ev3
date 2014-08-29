require "ev3/motor"
require "ev3/port"
require "ev3/button"

require 'ev3/command'
require 'ev3/command_component'

require 'ev3/actions/brick'

module EV3
  class Brick
    attr_reader :connection, :layer

    include EV3::Validations::Type
    include EV3::Actions::Brick

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
    
    def device_list(layer=@layer)
      c = _device_list
      self.execute(c)
      unless c.replies[1] == 0
        @device_list = c.replies[0].map{|i| DEVICE_TYPES[i]}
        @device_list = [[@device_list[0,4],  @device_list[16,4]], 
                        [@device_list[4,4],  @device_list[20,4]], 
                        [@device_list[8,4],  @device_list[24,4]], 
                        [@device_list[12,4], @device_list[28,4]]]
      end
      layer == -1 ? @device_list : @device_list[layer]
    end

    def poll_buttons(interval = 0.1, &block)
      command = Button.constants.map{|b| self.send("button_#{b.downcase}")._pressed?}
      Button.on_button_changed = block if block_given?
      @stop_polling = false
      
      Thread.new do
        while(not @stop_polling)
          self.execute(command)
          sleep(interval)
        end
      end.run
    end
    
    def stop_polling
      @stop_polling = true
    end
          
    # Play a short beep on the EV3
    def beep
      play_tone(50, 1000, 500)
    end

    # Play a tone on the EV3 using the specified options
    def play_tone(volume, frequency, duration)
      self.execute(_play_sound(volume, frequency, duration))
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
    
    Port::constants.each do |port|
      port_name = "port_#{port.downcase}"
      variable_name = "@#{port_name}"
      define_method(port_name) do
        if instance_variable_defined?(variable_name)
          instance_variable_get(variable_name)
        else
          instance_variable_set(variable_name, Port.new(Port::const_get(port), self))
        end
      end
    end    

    def port(port_name)
      send("port_#{port_name.to_s.downcase}")
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
      command = Command.new.add_component(command) if command.is_a?(CommandComponent) or command.is_a?(Array)
      self.connection.write(command)
      command.reply
    end
  end
end