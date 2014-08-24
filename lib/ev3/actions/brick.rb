module EV3
  module Actions
    module Brick
      private
      
      # TODO: Move into a validations module
      # 
      # Raises an exception if the value isn't found in the range
      #
      # @param [Integer] value to check against the range
      # @param [String] variable_name for the exception message
      # @param [Range<Integer>] range the value should be in
      def validate_range!(value, variable_name, range)
        raise(ArgumentError, "#{variable_name} should be between #{range.min} and #{range.max}") unless range.include?(value)
      end

      def _base(code, subcode=nil)
        CommandComponent.new(self, code, subcode)
      end

      def _play_sound(volume, frequency, duration)
        validate_range!(volume, 'volume', 0..100)
        validate_range!(frequency, 'frequency', 0..50_000) # 0 - 50,000 Hz
        validate_range!(duration, 'duration', 0..(1000 * 60 * 60 * 24 * 365)) # Up to a year

        _base(ByteCodes::SOUND, SoundSubCodes::TONE)
          .add_parameter(:byte, volume)
          .add_parameter(:short, frequency)
          .add_parameter(:short, duration)
      end
    end
  end
end
