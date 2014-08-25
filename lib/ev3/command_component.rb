module EV3
  class CommandComponent
    using EV3::CoreExtensions

    include EV3::Validations::Constant
    include EV3::Validations::Type

    attr_reader :reply_size

    SIZE_OF = {
                :byte   => 1,
                :short  => 2,
                :int    => 4,
                :float  => 4
              }

    UNPACK_CONVERSION = {
                :byte   => "c",
                :short  => "v",
                :int    => "V",
                :float  => "F"
              }

    def initialize(object, type, subtype=nil)
      @object = object
      @type = type
      @subtype = subtype

      @parameters = []
      @reply_types = []
      @reply_size = 0
    end
    
    def has_reply?
      @reply_size != 0
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

    def add_reply(type, setter)
      # TODO: Figure out how to handle null terminated strings
      @reply_types << [type, setter]
      @reply_size += SIZE_OF[type]
      self
    end

    def to_bytes(index=0)
      @bytes = []

      self << @type
      self << @subtype if @subtype

      @parameters.each do |type, value_or_getter|
        self << ArgumentType.const_get(type.to_s.upcase)
        value = value_or_getter.is_a?(Symbol) ? @object.send(value_or_getter) : value_or_getter
        self << value.to_little_endian_byte_array(SIZE_OF[type]) 
      end

      @reply_types.each do |type, setter|
        self << ArgumentType::GLOBAL_INDEX
        self << index
        index += SIZE_OF[type]
      end
      @bytes
    end

    def reply=(bytes)
      index = 0
      @reply_types.each do |type, setter|
        my_bytes = bytes[index..(index + SIZE_OF[type] - 1)]
        data = my_bytes.pack("C*").unpack(UNPACK_CONVERSION[type])[0]
        @object.send(setter, data)
        index += SIZE_OF[type]
      end      
    end
  end
end