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
      connect
    end

    ############################################################################
    #
    # Connection
    # 

    # Check to see if connected to the EV3
    def connected?
      self.connection.connected?
    end

    # Connect to the EV3
    def connect
      self.connection.connect unless connected?
    end

    # Close the connection to the EV3
    def disconnect
      self.connection.disconnect if connected?
    end
    
    def firmware_version
      brick.execute(_firmware_version)
      @firmware_version
    end
    
    ############################################################################
    #
    # Devices
    # 
    # Check what's attached to each port
    #
    
    def device_list(layer=@layer)
      c = _device_list
      self.execute(c)
      if @device_list.nil? or c.replies[1] != 0
        @device_list = c.replies[0].map{|i| DEVICE_TYPES[i]}
        @device_list = [[@device_list[0,4],  @device_list[16,4]], 
                        [@device_list[4,4],  @device_list[20,4]], 
                        [@device_list[8,4],  @device_list[24,4]], 
                        [@device_list[12,4], @device_list[28,4]]]
      end
      layer == -1 ? @device_list : @device_list[layer]
    end

    ############################################################################
    #
    # LED
    #
    
    def led_pattern(pattern)
      self.execute(_led_pattern(pattern))
    end

    ############################################################################
    #
    # Sound
    #
    
    # Play a short beep on the EV3
    def beep
      play_tone(50, 1000, 500)
    end

    # Play a tone on the EV3 using the specified options
    def play_tone(volume, frequency, duration)
      self.execute(_play_sound(volume, frequency, duration))
    end

    ############################################################################
    #
    # Motors
    #
    
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
    
    ############################################################################
    #
    # Ports
    #
    
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

    # Fetches the port attached to the specified port name
    # @param [sym in [:one, :two, :three, :four, :a, :b, :c, :d]] port_name
    # @example get port related to port a
    #   port_a = brick.port(:a)
    def port(port_name)
      send("port_#{port_name.to_s.downcase}")
    end
    
    ############################################################################
    #
    # Buttons
    #
    
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
    # @example get left button
    #   button_left = brick.button(:left)
    def button(button_name)
      send("button_#{button_name.to_s.downcase}")
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
    
    def stop_polling_buttons
      @stop_polling = true
    end
    
    ############################################################################
    #
    # Drawing
    #

    def update_screen
      if @update
        @update << _update_screen
        self.execute(@update)
        @update = nil
      else
        self.execute(_update_screen)
      end
    end

    def start_screen_update
      @update ||= []
    end

    def clean_screen
      if @update
        @update << _clean_screen
      else 
        self.execute([_clean_screen, _update_screen])
      end
    end

    def top_line(trueOrFalse)
      if @update
        @update << _top_line(trueOrFalse)
      else 
        self.execute([_top_line(trueOrFalse), _update_screen])
      end
    end

    def draw_line(color, x0, y0, x1, y1)
      if @update
        @update << _draw_line(color, x0, y0, x1, y1)
      else 
        self.execute([_draw_line(color, x0, y0, x1, y1), _update_screen])
      end
    end

    def draw_dot_line(color, x0, y0, x1, y1, on_pixels, off_pixels)
      if @update
        @update << _draw_dot_line(color, x0, y0, x1, y1, on_pixels, off_pixels)
      else 
        self.execute([_draw_dot_line(color, x0, y0, x1, y1, on_pixels, off_pixels), _update_screen])
      end
    end

    def draw_pixel(color, x, y)
      if @update
        @update << _draw_pixel(color, x, y)
      else 
        self.execute([_draw_pixel(color, x, y), _update_screen])
      end
    end

    def draw_rectangle(color, x, y, width, height)
      if @update
        @update << _draw_rectangle(color, x, y, width, height)
      else 
        self.execute([_draw_rectangle(color, x, y, width, height), _update_screen])
      end
    end

    def draw_filled_rectangle(color, x, y, width, height)
      if @update
        @update << _draw_filled_rectangle(color, x, y, width, height)
      else 
        self.execute([_draw_filled_rectangle(color, x, y, width, height), _update_screen])
      end
    end

    def draw_inverse_rectangle(color, x, y, width, height)
      if @update
        @update << _draw_inverse_rectangle(color, x, y, width, height)
      else 
        self.execute([_draw_inverse_rectangle(color, x, y, width, height), _update_screen])
      end
    end

    def draw_circle(color, x, y, radius)
      if @update
        @update << _draw_circle(color, x, y, radius)
      else 
        self.execute([_draw_circle(color, x, y, radius), _update_screen])
      end
    end

    def draw_filled_circle(color, x, y, radius)
      if @update
        @update << _draw_filled_circle(color, x, y, radius)
      else 
        self.execute([_draw_filled_circle(color, x, y, radius), _update_screen])
      end
    end

    def draw_text(color, x, y, text)
      if @update
        @update << _draw_text(color, x, y, text)
      else 
        self.execute([_draw_text(color, x, y, text), _update_screen])
      end
    end
    
    def select_font(font)
      if @update
        @update << _select_font(font)
      else 
        self.execute([_select_font(font), _update_screen])
      end
    end
    
#		BMP_FILE = 0x1c
    
    ############################################################################
    #
    # Files
    #
      
    def create_dir(path)
      # Only have permission in "/home/root/lms2012/prjs/"
      c = _create_dir(path)
      self.execute(c)
      true
    end
          
    def delete_file(path)
      c = _delete_file(path)
      self.execute(c)
      true
    end
          
    def list_files(path)
      c = _list_files(path)
      self.execute(c)
      puts c.replies[3]      
    end
          
    ############################################################################
    #
    # Execute a command
    #
    # @param [instance subclassing Commands::Base] command to execute
    def execute(command, type=:direct)
      command = Command.new(type).add_component(command) if command.is_a?(CommandComponent) or command.is_a?(Array)
      self.connection.write(command)
      command.reply
    end
  end
end