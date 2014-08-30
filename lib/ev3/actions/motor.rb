module EV3
  module Actions
    module Motor
      using EV3::CoreExtensions

      private

      def _base(code, subcode=nil)
        CommandComponent.new(self, code, subcode).add_parameter(:byte, layer).add_parameter(:byte, motor)
      end

      def _start
        _base(ByteCodes::OUTPUT_START)
      end

      def _stop(brake)
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
        CommandComponent.new(self, ByteCodes::OUTPUT_GET_COUNT)
          .add_parameter(:byte, layer)
          .add_parameter(:byte, Math.log2(motor).to_i)
          .add_reply(:int)
      end

      def _read
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
        _base(ByteCodes::OUTPUT_POLARITY).add_parameter(:byte, polarity)
      end

      def _time_speed(speed, timing, brake)
        _base(ByteCodes::OUTPUT_TIME_SPEED)
          .add_parameter(:byte, speed)
          .add_parameter(:int, timing.is_a?(Array) ? timing : [0, timing, 0])
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
