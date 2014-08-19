module EV3
  module Commands
    class InputButtonPressed < Input
      using EV3::CoreExtensions

      def initialize(button)
        super(0, reply_size)

        validate_range!(button, 'button', 1..6)
        
        self << ByteCodes::UI_BUTTON
        self << ButtonSubCodes::PRESSED
        self << ArgumentType::BYTE
        self << button
			  self << ArgumentType::GLOBAL_INDEX
        self << 0x0
      end
      
      def reply_size
        0x1
      end
      
      def pressed?
        @reply[0] == 1
      end
    end
  end
end
