module EV3
  module Actions
    module Button
      private
      
      def _base(code, subcode=nil)
        CommandComponent.new(self, code, subcode).add_parameter(:byte, button)
      end

      def _pressed?
        _base(ByteCodes::UI_BUTTON, ButtonSubCodes::PRESSED).add_reply(:byte, :pressed=)
      end 
    end
  end
end
