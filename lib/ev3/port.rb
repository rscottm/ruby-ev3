require 'ev3/actions/port'

module EV3
  class Port
    include EV3::Validations::Constant
    include EV3::Validations::Type
    
    include EV3::Actions::Port

    attr_accessor :device_name, :type, :mode, :mode_name, :si, :raw, :percent
    
		ONE		= 0x00
		TWO		= 0x01
		THREE	= 0x02
		FOUR	= 0x03
    
		A		  = 0x10
		B		  = 0x11
		C		  = 0x12
		D		  = 0x13
    
    def initialize(port, brick)
      validate_constant!(port, 'port', self.class)
      validate_type!(brick, 'brick', EV3::Brick)

      @port = port
      @brick = brick
      @type = @mode = 0
    end
    
    def device_name
      brick.execute(_device_name)
      @device_name
    end

    def mode_name(m=@mode)
      brick.execute(_mode_name(m))
      @mode_name
    end

    def type
      brick.execute(_type_mode)
      DEVICE_TYPES[@type]
    end

    def mode
      brick.execute(_type_mode)
      @mode
    end

    def raw
      brick.execute(_ready_raw)
      @raw
    end

    def si
      brick.execute(_ready_si)
      @si
    end

    def percent
      brick.execute(_ready_percent)
      @percent
    end
    
    def query_modes
      modes = []
      0.upto(8) do |i|
        modes << _mode_name(i, nil)
      end
      brick.execute(modes)
      modes.map(&:reply) - [""]
    end

    private

    attr_reader :brick, :port

    # Helper for accessing the brick's layer (for daisy chaining)
    def layer
      brick.layer
    end
  end
end
