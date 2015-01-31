module EV3
  module Validations
    module Range
      using EV3::CoreExtensions

      # Raises an exception if the value isn't found in the range
      #
      # @param [Integer] value to check against the range
      # @param [String] variable_name for the exception message
      # @param [Range<Integer>] range the value should be in
      def validate_range!(value, variable_name, range)
        raise(ArgumentError, "#{variable_name} should be between #{range.min} and #{range.max}") unless range.include?(value)
      end
    end
  end
end
