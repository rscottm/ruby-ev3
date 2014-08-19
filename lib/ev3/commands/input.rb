module EV3
  module Commands
    class Input < Base
      using EV3::CoreExtensions

      attr_reader :reply
      
      # The command type [Overrides Base]
      # @return [CommandType]
      def command_type
        CommandType::DIRECT_COMMAND
      end
      
      # The reply type
      # @return [CommandType]
      def reply_type
        CommandType::DIRECT_REPLY
      end
      
      # The output command to run
      # @abstract
      # @return [ByteCodes]
      def command
        raise NotImplementedError
      end

      # Set the reply
      # @param [Array] bytes read in reply to the command sent
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
          raise IncorrectReplyType unless bytes.shift == reply_type
        else
          raise NoReplyType
        end
        
        # The remaining bytes are the reply
        if bytes.size == reply_size
          @reply = bytes
        else
          raise IncorrectReplySize
        end
      end
            
      # The size of the reply
      # @abstract
      # @return [Integer]
      def reply_size
        raise NotImplementedError
      end
    end
  end
end
