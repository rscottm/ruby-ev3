module EV3
  module Connections
    class Base

      def initialize
        @commands_sent = 0
      end

      def connect
        raise NotImplementedError
      end

      def write(command)
        @commands_sent += 1
        command.sequence_number = @commands_sent
        perform_write(command)
        perform_read(command) if command.has_reply?
        self
      end

      def perform_write(command)
        raise NotImplementedError
      end

      def perform_read(command)
        raise NotImplementedError
      end
    end

    # Base class for devices not found
    class DeviceNotFound < StandardError; end

    # Base class for rejected connections
    class ConnectionRejected < StandardError; end
  end
end