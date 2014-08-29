module EV3
  module Actions
    module Button
      def _pressed?
        _base(ByteCodes::UI_BUTTON, ButtonSubCodes::PRESSED).add_reply(:boolean, :pressed=)
      end 

      private

      def _base(code, subcode=nil)
        CommandComponent.new(self, code, subcode).add_parameter(:byte, button)
      end
    end
  end
end
