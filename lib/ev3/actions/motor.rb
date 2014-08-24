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
        _base(ByteCodes::OUTPUT_STOP).add_parameter(:byte, brake.to_ev3_data)
      end

      def _speed(speed)
        _base(ByteCodes::OUTPUT_SPEED).add_parameter(:byte, speed)
      end    

      def _polarity(polarity = 0)
        _base(ByteCodes::OUTPUT_POLARITY).add_parameter(:byte, polarity)
      end

      def _time_speed(speed, timing, brake)
        timing = [0, timing, 0] unless timing.is_a?(Array)
        _base(ByteCodes::OUTPUT_TIME_SPEED)
          .add_parameter(:byte, speed)
          .add_parameter(:int, timing[0])
          .add_parameter(:int, timing[1])
          .add_parameter(:int, timing[2])
          .add_parameter(:byte, brake.to_ev3_data)
      end
    end
  end
end
