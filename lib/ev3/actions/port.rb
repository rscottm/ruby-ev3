module EV3
  module Actions
    module Port
      private
      
      STRING_BUFFER_SIZE = 0x18
      
      def _base(code, subcode=nil)
        CommandComponent.new(self, code, subcode).add_parameter(:byte, layer).add_parameter(:byte, port)
      end
      
      def _device_name
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::GET_NAME)
          .add_parameter(:byte, STRING_BUFFER_SIZE) 
          .add_reply(:string, :device_name=, STRING_BUFFER_SIZE)
      end

      def _mode_name(m, rtn=:mode_name=)
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::GET_MODE_NAME)
          .add_parameter(:byte, m)        
          .add_parameter(:byte, STRING_BUFFER_SIZE) 
          .add_reply(:string, rtn, STRING_BUFFER_SIZE)
      end

      def _type_mode
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::GET_TYPE_MODE)
          .add_reply(:byte, :type=)
          .add_reply(:byte, :mode=)
      end
      
      def _get_raw
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::GET_RAW)
          .add_reply(:int, :raw=)
      end

      def _ready_raw
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::READY_RAW)
          .add_parameter(:byte, @type)
          .add_parameter(:byte, @mode)        
          .add_parameter(:byte, 0x01)       
          .add_reply(:int, :raw=)
      end

      def _ready_si
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::READY_SI)
          .add_parameter(:byte, @type)
          .add_parameter(:byte, @mode)        
          .add_parameter(:byte, 0x01)       
          .add_reply(:float, :si=)
      end

      def _ready_percent
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::READY_PCT)
          .add_parameter(:byte, @type)
          .add_parameter(:byte, @mode)        
          .add_parameter(:byte, 0x01)       
          .add_reply(:byte, :percent=)
      end
      
      def _get_min_max
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::GET_MIN_MAX)
          .add_reply(:float, :min=)
          .add_reply(:float, :max=)
      end
      
      def _get_changes
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::GET_CHANGES)
          .add_reply(:float, :changes=)
      end
      
      def _get_bumps
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::GET_BUMPS)
          .add_reply(:float, :bumps=)
      end
      
      def _clear_changes
        _base(ByteCodes::INPUT_DEVICE, InputSubCodes::CLR_CHANGES)
      end
    end
  end
end
