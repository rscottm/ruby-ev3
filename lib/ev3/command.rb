module EV3
  class Command
    using EV3::CoreExtensions

    include EV3::Validations::Constant
    include EV3::Validations::Type

    attr_reader :type
    attr_accessor :sequence_number
    
    def initialize(type = :direct)
      @type = type == :system ? CommandType::SYSTEM_COMMAND : CommandType::DIRECT_COMMAND
      @components = []
      @local_variables = @global_variables = 0
      @has_reply = false
      @reply_size = 0
    end
    
    def command_type
      @type
    end
    
    def has_reply?
      @has_reply
    end
    
    def reply_size
      @reply_size
    end
    
    def add_component(component)
      @components << component
      self
    end
    
    alias_method :<<, :add_component

    def to_bytes
      @bytes = []
      @reply_size = 0
      @has_reply = false
      
      @components.each do |c| 
        @bytes += c.to_bytes(@reply_size)
        if c.has_reply?
          @reply_size += c.reply_size
          @has_reply = true
        end
      end
      
      @global_variables = @reply_size      
      @type |= CommandType::WITHOUT_REPLY unless @has_reply
      
      message = self.sequence_number.to_little_endian_byte_array(2) + 
                  [type] + 
                  variable_size_bytes + 
                  @bytes.clone

      # The message is proceeded by the message length
      message.size.to_little_endian_byte_array(2) + message
    end
    
    def reply=(bytes)
      # First two bytes are the sequence_number
      if bytes.size >= 2
        sn = bytes.shift | (bytes.shift << 8) 
        raise IncorrectSequenceNumber unless sn == sequence_number
      else
        raise NoSequenceNumber
      end

      # Third byte is the reply_type
      if bytes.size >= 1
        raise IncorrectReplyType unless bytes.shift == CommandType::DIRECT_REPLY
      else
        raise NoReplyType
      end

      # The remaining bytes are the reply
      raise IncorrectReplySize if bytes.size != @reply_size

      @components.each do |c|
        if c.has_reply?
           c.reply = bytes[0..(c.reply_size-1)]
           bytes = bytes[c.reply_size..-1]
        end
      end
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
