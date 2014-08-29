module EV3
  class Command
    using EV3::CoreExtensions

    include EV3::Validations::Constant
    include EV3::Validations::Type

    attr_reader :type, :replies
    attr_accessor :sequence_number
    
    def initialize(type = :direct)
      @type = type == :system ? CommandType::SYSTEM_COMMAND : CommandType::DIRECT_COMMAND
      @components = []
      @local_variables = @global_variables = 0
      @has_reply = false
      @reply_size = 0
      @reply_type = 0
      @error_type = 0
    end
    
    def has_reply?
      @has_reply
    end
    
    def reply_size
      @reply_size
    end
    
    def add_component(component)
      if component.is_a?(Array)
        @components += component
      else
        @components << component
      end
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
      if @has_reply
        @reply_type = @type == CommandType::DIRECT_COMMAND ? CommandType::DIRECT_REPLY : CommandType::SYSTEM_REPLY
        @error_type = @type == CommandType::DIRECT_COMMAND ? CommandType::DIRECT_REPLY_WITH_ERROR : CommandType::SYSTEM_REPLY_WITH_ERROR
      else
        @type |= CommandType::WITHOUT_REPLY
      end
      
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
      raise NoReplyType if bytes.size == 0
      reply = bytes.shift
      raise ErrorReply if reply == @error_type
      raise IncorrectReplyType unless reply == @reply_type

      # The remaining bytes are the reply
      raise IncorrectReplySize if bytes.size != @reply_size
      
      @replies = []

      @components.each do |c|
        if c.has_reply?
           c.reply = bytes[0..(c.reply_size-1)]
           bytes = bytes[c.reply_size..-1]
           @replies += c.replies
        end
      end
    end
    
    def reply
      replies[0] if @replies
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
