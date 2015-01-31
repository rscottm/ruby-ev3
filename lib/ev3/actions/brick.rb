module EV3
  module Actions
    module Brick
      include EV3::Validations::Range

      private
      
      def _device_list
        CommandComponent.new(nil, ByteCodes::INPUT_DEVICE_LIST)
          .add_parameter(:byte, 0x20) 
          .add_reply(:byte, nil, 0x20)
          .add_reply(:byte)
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
