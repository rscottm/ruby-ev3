module EV3
  module Commands
    class Base
      using EV3::CoreExtensions

      include EV3::Validations::Constant
      include EV3::Validations::Type

      attr_accessor :sequence_number

      def initialize(local_variables = 0, global_variables = 0)
        @local_variables = local_variables
        @global_variables = global_variables

        # Sequence number is currently unused, so I am setting it to zero
        self.sequence_number = 0
        @bytes = []
      end

      # The command type.  Override if something other than CommandType::DIRECT_COMMAND_NO_REPLY
      # @return [CommandType]
      def command_type
        CommandType::DIRECT_COMMAND_NO_REPLY
      end

      # Converts the command to an array of bytes to send to the EV3
      def to_bytes
        message = self.sequence_number.to_little_endian_byte_array(2) + 
                    [command_type] + 
                    variable_size_bytes + 
                    @bytes.clone

        # The message is proceeded by the message length
        message.size.to_little_endian_byte_array(2) + message
      end

      # Append a byte or multiple bytes to the command
      #
      # @param [Integer, Array<Integer>] byte_or_bytes to append to the command
      def <<(byte_or_bytes)
        bytes = byte_or_bytes.arrayify
        bytes.each { |byte| @bytes << byte }
      end

      # String representation of the command
      def to_s
        "#{self.class.name}: #{self.to_bytes.map{|byte| byte.to_s(16)}.join(', ')}"
      end

      # Raises an exception if the value isn't found in the range
      #
      # @param [Integer] value to check against the range
      # @param [String] variable_name for the exception message
      # @param [Range<Integer>] range the value should be in
      def validate_range!(value, variable_name, range)
        raise(ArgumentError, "#{variable_name} should be between #{range.min} and #{range.max}") unless range.include?(value)
      end

      private

      def variable_size_bytes
        #   Byte 6    Byte 5
        #  76543210  76543210
        #  --------  --------
        #  llllllgg  gggggggg
        #
        #        gg  gggggggg  Global variables [0..MAX_COMMAND_GLOBALS]
        #  llllll              Local variables  [0..MAX_COMMAND_LOCALS]
        [
          (@global_variables & 0xFF),
          (((@local_variables << 2) & 0b1111_1100) | (((@global_variables >> 8) & 0b0000_0011)))
        ]
      end
    end
  end
end