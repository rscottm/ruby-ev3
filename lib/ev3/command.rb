#
# Command Structures
# 
# https://github.com/mindboards/ev3sources/blob/78ebaf5b6f8fe31cc17aa5dce0f8e4916a4fc072/lms2012/c_com/source/c_com.h
#
#  ,------,------,------,------,------,------,------,------,
#  |Byte 0|Byte 1|Byte 2|Byte 3|Byte 4|Byte 5|      |Byte n|
#  '------'------'------'------'------'------'------'------'
# 
# System Command Bytes:
#  Byte 0 – 1: Command size, Little Endian
#  Byte 2 – 3: Message counter, Little Endian
#  Byte 4:     Command type
#  Byte 5:     System Command 
#  Byte 6 - n: Dependent on System Command
#
# System Command Response Bytes:
#  Byte 0 – 1: Reply size, Little Endian
#  Byte 2 – 3: Message counter, Little Endian
#  Byte 4:     Reply type
#  Byte 5:     System command this is the response to
#  Byte 6:     Reply status
#  Byte 7 - n: Response dependent on System Command
#  
# Direct Command Bytes:
#  Byte 0 – 1: Command size, Little Endian
#  Byte 2 – 3: Message counter, Little Endian
#  Byte 4:     Command type
#  Byte 5 - 6: Number of global and local variables (compressed).
#               Byte 6    Byte 5
#              76543210  76543210
#              --------  --------
#              llllllgg  gggggggg
#                    gg  gggggggg  Global variables [0..MAX_COMMAND_GLOBALS]
#              llllll              Local variables  [0..MAX_COMMAND_LOCALS]
#  Byte 7 - n: Byte codes
#
# Direct Command Response Bytes:
#  Byte 0 – 1: Reply size, Little Endian
#  Byte 2 – 3: Message counter, Little Endian
#  Byte 4:     Reply type. see following defines
#  Byte 5 - n: Response buffer (global variable values)
#

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
    
    def direct_command?
      (type & CommandType::SYSTEM_COMMAND == 0)
    end
    
    def system_command?
      not direct_command?
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
        @bytes += c.to_bytes(@reply_size, direct_command? ? :direct : :system)
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
                  (direct_command? ? variable_size_bytes : []) + 
                  @bytes.clone

      # The message is proceeded by the message length
      message.size.to_little_endian_byte_array(2) + message
    end
    
    def reply=(bytes)
      # First two bytes are the sequence_number
      if bytes.size >= 2
        sn = bytes.shift | (bytes.shift << 8) 
        raise "Incorrect sequence number" unless sn == sequence_number
      else
        raise "No sequence number"
      end

      # Third byte is the reply_type
      raise "No reply type" if bytes.size == 0
      reply = bytes.shift
      raise "Incorrect reply type" unless [@reply_type, @error_type].include?(reply)

      @replies = []

      if direct_command?
        raise("Command returned an error") if reply == @error_type
        # The remaining bytes are the reply
        raise "Incorrect reply size" if bytes.size != @reply_size
        
        @components.each do |c|
          if c.has_reply?
             c.reply = bytes[0..(c.reply_size-1)]
             bytes = bytes[c.reply_size..-1]
             @replies += c.replies
          end
        end
      else
        raise("Command returned error: #{bytes[1]}") if reply == @error_type
        cmd = bytes.shift
        raise("Commmand return does not match!") unless cmd == @components[0].type
        @components[0].reply = bytes
        @replies += @components[0].replies
      end
    end
    
    def reply
      replies[0] if @replies
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
