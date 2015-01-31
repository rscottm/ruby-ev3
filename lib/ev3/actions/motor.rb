module EV3
  module Actions
    module Motor
      include EV3::Validations::Type
      include EV3::Validations::Range

      private

      def _base(code, subcode=nil)
        CommandComponent.new(self, code, subcode).add_parameter(:byte, layer).add_parameter(:byte, motor)
      end

      def _start
        _base(ByteCodes::OUTPUT_START)
      end

      def _stop(brake)
        validate_type!(brake, 'brake', [TrueClass, FalseClass])

        _base(ByteCodes::OUTPUT_STOP).add_parameter(:boolean, brake)
      end

      def _reset
        _base(ByteCodes::OUTPUT_RESET)
      end

      def _ready
        _base(ByteCodes::OUTPUT_READY)
      end

      def _test
        _base(ByteCodes::OUTPUT_TEST).add_reply(:byte)
      end

      def _clear_count
        _base(ByteCodes::OUTPUT_CLR_COUNT)
      end

      def _get_count
        raise(InvocationError, "don't call get count on multiple motors") unless Math.log2(motor).to_i == Math.log2(motor)

        CommandComponent.new(self, ByteCodes::OUTPUT_GET_COUNT)
          .add_parameter(:byte, layer)
          .add_parameter(:byte, Math.log2(motor).to_i)
          .add_reply(:int)
      end

      def _read
        raise(InvocationError, "don't call read on multiple motors") unless Math.log2(motor).to_i == Math.log2(motor)

        # The first reply should be a byte, but it throws an error unless it's an int.
        CommandComponent.new(self, ByteCodes::OUTPUT_READ)
          .add_parameter(:byte, layer)
          .add_parameter(:byte, Math.log2(motor).to_i)
          .add_reply(:int)
          .add_reply(:int)
      end

      def _speed(speed)
        _base(ByteCodes::OUTPUT_SPEED).add_parameter(:byte, speed)
      end    

      def _power(power)
        _base(ByteCodes::OUTPUT_POWER).add_parameter(:byte, power)
      end    

      def _polarity(polarity = 0)
        validate_range!(polarity, 'polarity', -1..1)        
        _base(ByteCodes::OUTPUT_POLARITY).add_parameter(:byte, polarity)
      end
      
      def _move(time:nil, step:nil, speed:nil, power:nil, turn:nil, brake:false)
        raise(ArgumentError, "specify time or step (but not both)") unless time.nil? ^ step.nil?
        raise(ArgumentError, "specify speed or power (but not both)") unless speed.nil? ^ power.nil?
        raise(ArgumentError, "specify speed when using turn") if speed.nil? and not turn.nil?
        raise(ArgumentError, "don't specify power when using turn") if not power.nil? and not turn.nil?
        raise(ArgumentError, "don't specify turn on a single motor") if turn and Math.log2(motor).to_i == Math.log2(motor)

        time_or_step = ((not time.nil? and time) or (not step.nil? and step))
        time_or_step_type = ((not time.nil? and :time) or (not step.nil? and :step))
        
        speed_or_power = ((not speed.nil? and speed) or (not power.nil? and power))
        speed_or_power_type = ((not speed.nil? and :speed) or (not power.nil? and :power))
        
        validate_range!(speed_or_power, speed_or_power_type.to_s, -100..100)        
        validate_type!(brake, 'brake', [TrueClass, FalseClass])
        
        if turn.nil?
          time_or_step = [0, time_or_step, 0] unless time_or_step.is_a?(Array)
          validate_range!(time_or_step[0], "#{time_or_step_type} up", 0..0xFFFFFFFF)        
          validate_range!(time_or_step[1], time_or_step_type.to_s, 0..0xFFFFFFFF)        
          validate_range!(time_or_step[2], "#{time_or_step_type} down", 0..0xFFFFFFFF)
          code = ByteCodes.const_get("OUTPUT_#{time_or_step_type.upcase}_#{speed_or_power_type.upcase}")
        else
          validate_range!(time_or_step, time_or_step_type.to_s, 0..0xFFFFFFFF)        
          validate_range!(turn, 'turn', -200..200)        
          code = ByteCodes.const_get("OUTPUT_#{time_or_step_type.upcase}_SYNC")
        end

        c = _base(code).add_parameter(:byte, speed_or_power)
        c.add_parameter(:short, turn) unless turn.nil?
        c.add_parameter(:uint, time_or_step).add_parameter(:boolean, brake)        
      end

      def _time_speed(speed, timing, brake)
        timing = [0, timing, 0] unless timing.is_a?(Array)
        
        validate_range!(speed, 'speed', -100..100)        
        validate_range!(timing[0], 'time up', 0..0xFFFFFFFF)        
        validate_range!(timing[1], 'time', 0..0xFFFFFFFF)        
        validate_range!(timing[2], 'time down', 0..0xFFFFFFFF)
        validate_type!(brake, 'break', Boolean)        

        _base(ByteCodes::OUTPUT_TIME_SPEED)
          .add_parameter(:byte, speed)
          .add_parameter(:uint, timing)
          .add_parameter(:boolean, brake)
      end

      def _step_power(power, steps, brake)
        _base(ByteCodes::OUTPUT_STEP_POWER)
          .add_parameter(:byte, power)
          .add_parameter(:int, steps.is_a?(Array) ? steps : [0, steps, 0])
          .add_parameter(:boolean, brake)
      end

      def _time_power(power, timing, brake)
        _base(ByteCodes::OUTPUT_TIME_POWER)
          .add_parameter(:byte, power)
          .add_parameter(:int, timing.is_a?(Array) ? timing : [0, timing, 0])
          .add_parameter(:boolean, brake)
      end

      def _step_speed(speed, steps, brake)
        _base(ByteCodes::OUTPUT_STEP_SPEED)
          .add_parameter(:byte, speed)
          .add_parameter(:int, steps.is_a?(Array) ? steps : [0, steps, 0])
          .add_parameter(:boolean, brake)
      end
      
      def _step_sync(speed, turn, step, brake)
        _base(ByteCodes::OUTPUT_STEP_SYNC)
          .add_parameter(:byte, speed)
          .add_parameter(:short, turn)
          .add_parameter(:uint, step)
          .add_parameter(:boolean, brake)
      end
      
      def _time_sync(speed, turn, time, brake)
        _base(ByteCodes::OUTPUT_TIME_SYNC)
          .add_parameter(:byte, speed)
          .add_parameter(:short, turn)
          .add_parameter(:uint, time)
          .add_parameter(:boolean, brake)
      end
    end
  end
end
