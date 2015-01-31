require 'ev3/actions/motor'

module EV3
  # High-level interface for interacting with Motors.
  # @todo Implement methods to read motor speed and tacho information.
  class Motor
    include EV3::Validations::Constant
    include EV3::Validations::Type
    
    include EV3::Actions::Motor

    A = 1
    B = 2
    C = 4
    D = 8
    
    AD = A | D
    BC = B | C
    
    # Create a new motor and perform some initial setup, stopping the motor and zeroing the speed.
    # @param [Motor] motor A, B, C or D constant, corresponding to the EV3 motor ports.
    # @param [EV3::Brick] brick the brick the motor is connected to.
    #
    # @example Motor attached to port A of brick
    #   EV3::Motor.new(EV3::Motor::A, brick)
    def initialize(motor, brick)
      validate_constant!(motor, 'motor', self.class)
      validate_type!(brick, 'brick', EV3::Brick)

      @motor = motor
      @brick = brick
      # Setting the motor speed before calling start appears to be necessary
      self.speed = 0
      stop
    end
    
    # Starts the motor.  Default speed is zero, and should be controlled with {#speed}.
    def start
      @on = true
      brick.execute(_start)
    end

    # Stop the motor
    # @param [true, false] brake stops the motor faster and holds it in position if true.
    def stop(brake = false)
      @on = false
      brick.execute(_stop(brake))
    end

    def reset
      brick.execute(_reset)
    end

    def ready
      brick.execute(_ready)
    end

    def test
      brick.execute(c = _test)
      c.reply == 0 ? :ready : :busy
    end

    def clear_count
      brick.execute(_clear_count)
    end

    def get_count
      brick.execute(_get_count)
    end

    def read
      rv = brick.execute(c = _read)
      puts "Speed = #{c.replies[0]}; Degrees = #{c.replies[1]}"
      rv
    end

    # @return [Boolean] true if the motor has started, false otherwise.
    def on?
      @on
    end

    # @return [int] the speed the motor is set to run at.
    # @note This is not necessarily the speed the motor is actually running at.
    # @note This is zero when the motor is stopped.
    def speed
      #on? ? @speed : 0
      brick.execute(_read)
    end

    # Sets the speed of the motor.
    # @param [int] new_speed from -100..100.
    #
    # @note The brick is only updated if the speed is changing.
    def speed=(new_speed)
      if @speed.nil? || new_speed != @speed
        @speed = new_speed
        brick.execute(_speed(new_speed))
      end
    end
    
    def power=(new_power)
      brick.execute(_power(new_power))
    end
    
    def move(hash)
      brick.execute(_move(hash))
    end

    def time_speed(speed, timing, brake=false)
#      brick.execute(_time_speed(speed, timing, brake))
      brick.execute(_move(time:timing, speed:speed, brake:brake))
    end

    def step_power(power, steps, brake=false)
      brick.execute(_step_power(power, steps, brake))
    end

    def time_power(power, timing, brake=false)
      brick.execute(_time_power(power, timing, brake))
    end

    def step_speed(speed, steps, brake=false)
      brick.execute(_step_speed(speed, steps, brake))
    end

    def step_sync(speed, turn, step, brake=false)
      brick.execute(_step_sync(speed, turn, step, brake))
    end

    def time_sync(speed, turn, time, brake=false)
      brick.execute(_time_sync(speed, turn, time, brake))
    end

    # Causes the motor to run in the reverse direction.
    # @note This doesn't change the speed reading, just the direction the motor spins.  In other words, positive
    #   speeds result in the motor spinning in the opposite direction.
    def reverse
      brick.execute(_polarity)
    end

    private

    attr_reader :brick, :motor

    # Helper for accessing the brick's layer (for daisy chaining)
    def layer
      brick.layer
    end
  end
end