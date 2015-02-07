module EV3
  class CommandComponent
    using EV3::CoreExtensions

    include EV3::Validations::Constant
    include EV3::Validations::Type

    attr_reader :reply_size, :replies, :type

    SIZE_OF = {
                :boolean => 1,
                :byte   => 1,
                :ubyte  => 1,
                :short  => 2,
                :ushort => 2,
                :int    => 4,
                :uint   => 4,
                :float  => 4,
                :string => 1
              }

    UNPACK_CONVERSION = {
                :boolean => "c*",
                :byte   => "c*",
                :ubyte  => "C*",
                :short  => "s<*",
                :ushort => "S<*",
                :int    => "l<*",
                :uint   => "L<*",
                :float  => "e*"
              }

    def initialize(object, type, subtype=nil)
      @object = object
      @type = type
      @subtype = subtype

      @parameters = []
      @reply_types = []
      @reply_size = 0
    end
    
    # Append a byte or multiple bytes to the command
    #
    # @param [Integer, Array<Integer>] byte_or_bytes to append to the command
    def <<(byte_or_bytes)
      bytes = byte_or_bytes.arrayify
      bytes.each { |byte| @bytes << byte }
    end

    def add_parameter(type, value_or_getter)
      @parameters << [type, value_or_getter]
      self
    end

    def add_reply(type, setter=nil, buffer_or_array_size=0)
      @reply_types << [type, setter, buffer_or_array_size]
      @reply_size += buffer_or_array_size > 0 ? (buffer_or_array_size * SIZE_OF[type]) : SIZE_OF[type]
      self
    end

    def to_bytes(index=0, command_type=:direct)
      @bytes = []

      self << @type
      self << @subtype if @subtype

      @parameters.each do |type, value_or_getter|
        value = value_or_getter.is_a?(Symbol) ? @object.send(value_or_getter) : value_or_getter
        value = [value] unless value.is_a?(Array)
        value.each do |v|
          self << ArgumentType.const_get(type.to_s.upcase) if command_type == :direct
          v = v.to_ev3_data if type == :boolean
          self << (type == :string ? v.unpack("U*").push(0) : v.to_little_endian_byte_array(SIZE_OF[type]))
        end
      end

      @reply_types.each do |type, setter, buffer_or_array_size|
        if command_type == :direct
          self << ArgumentType::GLOBAL_INDEX
          self << index
          index += buffer_or_array_size > 0 ? (buffer_or_array_size * SIZE_OF[type]) : SIZE_OF[type]
        end
      end
      @bytes
    end

    def reply=(bytes)
      @replies = []
      index = 0
      
      @reply_types.each do |type, setter, buffer_or_array_size|
        size = buffer_or_array_size > 0 ? (buffer_or_array_size * SIZE_OF[type]) : SIZE_OF[type]
        data = bytes[index..(index + size - 1)]
        if type == :string
          data = data[0..(data.find_index(0))] if data.find_index(0)
          data = data.pack("C*")
          data.strip!
        else
          data = data.pack("C*")
          data = data.unpack(UNPACK_CONVERSION[type])
          data = data[0] if buffer_or_array_size == 0 
          data = data == 1 if type == :boolean
        end
        @replies << data
        @object.send(setter, data) if setter
        index += size
      end
      @replies
    end
    
    def has_reply?
      @reply_size != 0
    end

    def replies
      @replies
    end
 
    def reply(num=0)
      @replies[num]
    end
  end
end